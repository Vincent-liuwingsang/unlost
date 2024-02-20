from src.memory import Memory
from .state import get_nlp
from .cluster_rectangles import cluster_intersecting_rectangles
import copy

nlp = get_nlp()


def rect_ocr_to_min_max(rect):
    return [rect[0], 1 - rect[1], rect[0] + rect[2], 1 - rect[1] + rect[3]]


def rect_min_max_to_ocr(rect):
    return [rect[0], 1 - rect[1], rect[2] - rect[0], rect[3] - rect[1]]


def get_adjusted_rectangles(rows: list[Memory]):
    adjusted_rectangles = []
    adjusted_rectangle_to_result = {}
    rectangle_to_result = {}
    adjusted_rectangle_to_rectangle = {}
    for x in rows:
        adjusted_rectangle = rect_ocr_to_min_max(x.location)
        adjusted_rectangles.append(adjusted_rectangle)
        adjusted_rectangle_to_result[str(adjusted_rectangle)] = x
        rectangle_to_result[str(x.location)] = x
        adjusted_rectangle_to_rectangle[str(adjusted_rectangle)] = str(x.location)

    return (
        adjusted_rectangles,
        adjusted_rectangle_to_result,
        rectangle_to_result,
        adjusted_rectangle_to_rectangle,
    )


def cluster_needs_processing(cluster):
    # if single rectangle, don't process
    if len(cluster) == 1:
        return False

    # if first two rectangles are on same line, then assume its not a valid paragraph block and don't process
    h = cluster[0][3] - cluster[0][1]
    if abs(cluster[1][1] - cluster[0][1]) < h / 2:
        return False

    return True


def transform_memory(memories: list[Memory]) -> list[Memory]:
    # filter out results that are too high
    first_memory = Memory.from_memory(memories[0])
    screenshot_id = first_memory.id.split("#")[0]
    height = first_memory.screenshot_height
    valid_memories = [x for x in memories if (1 - x.location[1]) * height > 90]

    (
        adjusted_rectangles,
        adjusted_rectangle_to_result,
        rectangle_to_result,
        adjusted_rectangle_to_rectangle,
    ) = get_adjusted_rectangles(valid_memories)

    updated_memories = []
    clustered = cluster_intersecting_rectangles(adjusted_rectangles, 0.35)
    sentence_index = 0
    for cluster in clustered:
        if not cluster_needs_processing(cluster):
            for rect in cluster:
                new_memory = Memory.from_memory(
                    rectangle_to_result[adjusted_rectangle_to_rectangle[str(rect)]]
                )

                new_memory.id = f"{screenshot_id}#{sentence_index}"
                updated_memories.append(new_memory)
                sentence_index += 1
            continue

        original_lengths = []
        block = []

        sorted_rects = sorted(cluster, key=lambda x: (x[1], x[0]))
        for i, rect in enumerate(sorted_rects):
            item = adjusted_rectangle_to_result[str(rect)]
            text = item.text
            next_length = (
                original_lengths[-1] + len(text) if len(original_lengths) else len(text)
            )
            if i < len(sorted_rects) - 1:
                next_length += 1

            original_lengths.append(next_length)
            block.append(text)
        block = " ".join(block)

        doc = nlp(block)
        current = 0
        prev = 0
        for sentence in doc.sents:
            # nlp strips whitespace when splitting sentences, so we need to add it back
            current += len(str(sentence)) + 1

            start_sub_block = None
            start_sub_block_offset = 0
            end_sub_block = None
            end_sub_block_offset = 0
            for index, l in enumerate(original_lengths):
                if index + 1 <= len(original_lengths) - 1:
                    # print(prev, current, l, prev != 0 and prev > l, current > l, adjusted_rectangle_to_result[str(sorted_rects[index])][0])
                    if prev >= l:
                        start_sub_block = index + 1
                        start_sub_block_offset = prev - l
                    if current > l:
                        end_sub_block = index + 1
                        end_sub_block_offset = current - l

            if start_sub_block is None:
                start_sub_block = 0
                start_sub_block_offset = 0
            if end_sub_block is None:
                end_sub_block = 0
                end_sub_block_offset = len(str(sentence)) + 1

            # print(start_sub_block, end_sub_block)
            if start_sub_block is not None and end_sub_block is not None:
                original_sub_blocks = copy.deepcopy(
                    sorted_rects[start_sub_block : end_sub_block + 1]
                )
                sub_blocks = copy.deepcopy(original_sub_blocks)
                # print([adjusted_rectangle_to_result[str(x)][0] for x in sub_blocks])
                x = sub_blocks[0]
                text = adjusted_rectangle_to_result[str(x)].text
                offset_by = start_sub_block_offset / len(text)

                original_width = x[2] - x[0]
                sub_blocks[0] = [x[0] + original_width * offset_by, x[1], x[2], x[3]]

                if len(sub_blocks) > 1:
                    x = sub_blocks[-1]
                    next_block_index = sorted_rects.index(x)
                    if next_block_index < len(sorted_rects):
                        next_text = adjusted_rectangle_to_result[
                            str(sorted_rects[next_block_index])
                        ].text
                        offset_by = end_sub_block_offset / len(next_text)

                        original_width = x[2] - x[0]
                        sub_blocks[-1] = [
                            x[0],
                            x[1],
                            x[0] + original_width * offset_by,
                            x[3],
                        ]

                new_memory = Memory.from_memory(first_memory)
                new_memory.id = f"{screenshot_id}#{sentence_index}"
                new_memory.text = str(sentence)
                new_memory.location = [
                    item
                    for sublist in sub_blocks
                    for item in rect_min_max_to_ocr(sublist)
                ]
                updated_memories.append(new_memory)
                sentence_index += 1

            prev = current
    return updated_memories
