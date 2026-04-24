from spiders.example import parse


def test_parse_yields_dict() -> None:
    out = list(parse("<html></html>"))
    assert out
    assert out[0]["len"] == len("<html></html>")
