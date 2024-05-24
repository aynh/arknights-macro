import httpx

import itertools
import os
from datetime import date

tl_tags: list[dict] = httpx.get(
    "https://raw.githubusercontent.com/Aceship/AN-EN-Tags/master/json/tl-tags.json"
).json()
tl_akhr: list[dict] = httpx.get(
    "https://raw.githubusercontent.com/Aceship/AN-EN-Tags/master/json/tl-akhr.json"
).json()
tl_type: list[dict] = httpx.get(
    "https://raw.githubusercontent.com/Aceship/AN-EN-Tags/master/json/tl-type.json"
).json()
tl_unreadablename: list[dict] = httpx.get(
    "https://raw.githubusercontent.com/Aceship/AN-EN-Tags/master/json/tl-unreadablename.json"
).json()


def main():
    raw_operator_pool = [
        operator
        for operator in tl_akhr
        if not (operator.get("globalHidden") or operator["hidden"])
    ]

    operator_pool: list[dict] = []
    for operator in raw_operator_pool:
        operator_pool.append(
            {
                "name": translate_unreadable_name(operator["name_en"]),
                "rarity": operator["level"],
                "tags": [
                    translate_type(operator["type"]),
                    *(translate_tag(tag) for tag in operator["tags"]),
                ],
            }
        )
    operator_pool.sort(key=lambda operator: (operator["rarity"], operator["name"]))

    os.chdir(os.path.dirname(__file__))
    with open("../AutoRecruit.ahk", "r") as f:
        data = []
        while line := f.readline():
            data.append(line)
            if "---" in line:
                break

    data.append("\n")
    data.append(f"; Last updated: {date.today()}\n")

    data.append("\n")
    data.append("combinations := [\n")
    for idx in range(1, 4):
        data.append(" ")
        for combination in itertools.combinations([1, 2, 3, 4, 5], idx):
            data.append(f" {list(combination)},")
        data.append("\n")
    data.append("]\n")

    data.append("\n")
    data.append("operators := [\n")
    for operator in operator_pool:
        data.append(f"  Operator{tuple(operator.values())},\n")
    data.append("]\n")

    with open("../AutoRecruit.ahk", "w") as f:
        for line in data:
            f.write(line)


# translates cn tag to en
def translate_tag(tag):
    for tag_dict in tl_tags:
        if tag_dict["tag_cn"] == tag:
            return tag_dict["tag_en"]

    raise ValueError(f"No EN translation for {tag}")


# translates cn type (class) to en
def translate_type(typ):
    for typ_dict in tl_type:
        if typ_dict["type_cn"] == typ:
            return typ_dict["type_en"]

    raise ValueError(f"No EN translation for {typ}")


# translates unreadable name to en
def translate_unreadable_name(name):
    for name_dict in tl_unreadablename:
        if name_dict["name"] == name:
            return name_dict["name_en"]

    return name


if __name__ == "__main__":
    main()
