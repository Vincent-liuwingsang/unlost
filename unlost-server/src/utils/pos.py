from typing import Literal
from pydantic import BaseModel
import re
import dateparser
from datetime import datetime, timedelta
from pathlib import Path

from .state import get_nlp

import calendar

nlp = get_nlp()

contains_number_regex = r"\d"


def contains_number(input_string):
    return bool(re.search(contains_number_regex, input_string))


after_date = {"from", "since", "over", "after"}
before_date = {"upto", "before", "until", "till", "by", "before"}
range_date = {"in", "within", "during"}
exact_date = {"on", "at"}
weekdays = {
    "monday",
    "tuesday",
    "wednesday",
    "thursday",
    "friday",
    "saturday",
    "sunday",
    "mon",
    "tue",
    "wed",
    "thu",
    "fri",
    "sat",
    "sun",
}
weekdaysToInt = {
    "monday": 0,
    "tuesday": 1,
    "wednesday": 2,
    "thursday": 3,
    "friday": 4,
    "saturday": 5,
    "sunday": 6,
    "mon": 0,
    "tue": 1,
    "wed": 2,
    "thu": 3,
    "fri": 4,
    "sat": 5,
    "sun": 6,
}


class POSResult(BaseModel):
    range_type: Literal[
        "after", "before", "range_week", "range_month", "range_year", "exact"
    ]
    parsed_date: datetime
    clean_text: str
    from_date: datetime
    to_date: datetime


def get_date_condition(
    sentence: str,
) -> POSResult | None:
    doc = nlp(sentence)
    date_text = ""
    for entity in doc.ents:
        if entity.label_ == "DATE" or entity.label_ == "TIME":
            date_text = entity.text
            break
    if not date_text:
        return None

    identified_date_text = date_text
    range_type = "exact"

    clean = sentence.split(date_text)[0].strip()

    if clean.split(" ")[-1].lower() == "past":
        clean = " ".join(clean.split(" ")[:-1])
        date_text = f"last {date_text}"
        identified_date_text = f"past {identified_date_text}"

    # print("clear: ", clean, ", data_text: ", date_text)

    if clean:
        # print(splitted)
        relative = [x for x in clean.split(" ") if x][-1].lower()
        # print(relative)
        if relative in after_date:
            range_type = "after"
            clean = clean.replace(relative, "")
            identified_date_text = f"{relative} {identified_date_text}"
        elif relative in before_date:
            range_type = "before"
            clean = clean.replace(relative, "")
            identified_date_text = f"{relative} {identified_date_text}"
        elif relative in range_date:
            if "week" in date_text:
                range_type = "range_week"
            if "month" in date_text:
                range_type = "range_month"
            if "year" in date_text:
                range_type = "range_year"

            clean = clean.replace(relative, "")
            identified_date_text = f"{relative} {identified_date_text}"
        else:
            if "week" in date_text:
                range_type = "range_week"
            if "month" in date_text:
                range_type = "range_month"
            if "year" in date_text:
                range_type = "range_year"
            if relative in exact_date:
                clean = clean.replace(relative, "")

    minus_1_week = False
    if "last" in date_text or "past" in date_text or "previous" in date_text:
        date_text = (
            date_text.lower()
            .replace("last", "")
            .replace("past", "")
            .replace("previous", "")
            .replace("this", "")
            .strip()
        )
        if contains_number(date_text):
            date_text += " ago"
        elif date_text in weekdays:
            if (
                weekdaysToInt[date_text] is not None
                and weekdaysToInt[date_text] < datetime.now().weekday()
            ):
                minus_1_week = True
        else:
            date_text = f"1 {date_text} ago"

    parsed_date = dateparser.parse(date_text)
    if not parsed_date:
        return None

    parsed_date = parsed_date + timedelta(days=-7) if minus_1_week else parsed_date
    from_date, to_date = get_from_to(range_type=range_type, parsed_date=parsed_date)
    return POSResult(
        range_type=range_type,
        parsed_date=parsed_date,
        clean_text=clean.strip(),
        from_date=from_date,
        to_date=to_date,
    )


def get_from_to(range_type: str, parsed_date: datetime):
    if range_type == "exact":
        return parsed_date, parsed_date
    elif range_type == "after":
        return parsed_date, datetime.max
    elif range_type == "before":
        return datetime.min, parsed_date
    elif range_type == "range_week":
        start_of_week = parsed_date - timedelta(
            days=parsed_date.weekday(),
            hours=parsed_date.hour,
            minutes=parsed_date.minute,
            seconds=parsed_date.second,
        )
        end_of_week = start_of_week + timedelta(
            days=6, hours=23, minutes=59, seconds=59
        )
        return start_of_week, end_of_week
    elif range_type == "range_month":
        first_day_of_month = parsed_date.replace(day=1, hour=0, minute=0, second=0)

        _, last_day = calendar.monthrange(parsed_date.year, parsed_date.month)
        last_day_of_month = parsed_date.replace(
            day=last_day, hour=23, minute=59, second=59
        )
        return first_day_of_month, last_day_of_month
    elif range_type == "range_year":
        first_day_of_year = parsed_date.replace(
            month=1, day=1, hour=0, minute=0, second=0
        )

        # Get the last day of the year
        last_day_of_year = parsed_date.replace(
            month=12, day=31, hour=23, minute=59, second=59
        )

        return first_day_of_year, last_day_of_year
