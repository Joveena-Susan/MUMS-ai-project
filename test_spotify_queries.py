from spotify_query import build_queries_for_languages


def test_english_queries_are_short():
    queries = build_queries_for_languages("Energetic", 80, ["english"])
    assert queries
    for q in queries:
        # no language-negation remnants
        assert "-bollywood" not in q
        assert "-hindi" not in q
        # length should be reasonably small (under 30 chars)
        assert len(q) < 30, f"Query too long: {q}"


def test_malayalam_queries_not_tainted():
    queries = build_queries_for_languages("Happy", 50, ["malayalam"])
    # should not see any negative keywords
    for q in queries:
        assert "-bollywood" not in q
        assert "-hindi" not in q

