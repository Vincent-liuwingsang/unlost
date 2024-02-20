import nltk
import pickle

f = open("./query_classifier.pickle", "rb")
classifier = pickle.load(f)
f.close()


def dialogue_act_features(post):
    features = {}
    for word in nltk.word_tokenize(post):
        features["contains({})".format(word.lower())] = True
    return features


def short_query_to_long_passage(q: str) -> bool:
    return classifier.classify(dialogue_act_features(q))
