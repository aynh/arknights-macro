import httpx

import itertools
import os
from datetime import date

os.chdir(os.path.dirname(__file__))  # goto the script directory
RECRUIT_TOOL_FILE_PATH = "../src/RecruitTool.ahk"

TL_TAGS: list[dict] = httpx.get(
    "https://raw.githubusercontent.com/Aceship/AN-EN-Tags/master/json/tl-tags.json"
).json()
TL_AKHR: list[dict] = httpx.get(
    "https://raw.githubusercontent.com/Aceship/AN-EN-Tags/master/json/tl-akhr.json"
).json()
TL_TYPE: list[dict] = httpx.get(
    "https://raw.githubusercontent.com/Aceship/AN-EN-Tags/master/json/tl-type.json"
).json()
TL_UNREADABLENAME: list[dict] = httpx.get(
    "https://raw.githubusercontent.com/Aceship/AN-EN-Tags/master/json/tl-unreadablename.json"
).json()


def main():
    raw_operator_pool = [
        operator
        for operator in TL_AKHR
        if not (operator.get("globalHidden") or operator["hidden"])
    ]

    operator_pool: list[dict] = []
    for operator in raw_operator_pool:
        operator_pool.append(
            {
                "name": translate_unreadable_name(operator["name_en"]),
                "rarity": operator["level"],
                "tags": list(
                    map(
                        normalize_tag,
                        [
                            translate_type(operator["type"]),
                            *(translate_tag(tag) for tag in operator["tags"]),
                        ],
                    )
                ),
            }
        )
    operator_pool.sort(key=lambda operator: (operator["rarity"], operator["name"]))

    known_tags = set()
    for operator in operator_pool:
        for tag in operator["tags"]:
            known_tags.add(tag)
    known_tags = sorted(known_tags)

    with open(RECRUIT_TOOL_FILE_PATH, "r") as f:
        data = []
        while line := f.readline():
            data.append(line)
            if "---" in line:
                break

    data.append("\n")
    data.append(f"; Last updated: {date.today()}\n")

    data.append("class RecruitToolData {\n")

    data.append("  static combinations := [\n")
    for idx in range(1, 4):
        data.append("   ")
        for combination in itertools.combinations([1, 2, 3, 4, 5], idx):
            data.append(f" {list(combination)},")
        data.append("\n")
    data.append("  ]\n")

    data.append("\n")
    data.append("  static known_tags := [\n")
    for tags in itertools.batched(known_tags, 5):
        data.append("   ")
        for tag in tags:
            data.append(f" '{tag}',")
        data.append("\n")
    data.append("  ]\n")

    data.append("\n")
    data.append("  static operators := [\n")
    for operator in operator_pool:
        data.append(f"    Operator{tuple(operator.values())},\n")
    data.append("  ]\n")

    data.append("}\n")

    with open(RECRUIT_TOOL_FILE_PATH, "w") as f:
        for line in data:
            f.write(line)


def normalize_tag(tag: str):
    return tag.lower().replace("-", " ")


# translates cn tag to en
def translate_tag(tag):
    for tag_dict in TL_TAGS:
        if tag_dict["tag_cn"] == tag:
            return tag_dict["tag_en"]

    raise ValueError(f"No EN translation for {tag}")


# translates cn type (class) to en
def translate_type(typ):
    for typ_dict in TL_TYPE:
        if typ_dict["type_cn"] == typ:
            return typ_dict["type_en"]

    raise ValueError(f"No EN translation for {typ}")


# translates unreadable name to en
def translate_unreadable_name(name):
    for name_dict in TL_UNREADABLENAME:
        if name_dict["name"] == name:
            return name_dict["name_en"]

    return name


if __name__ == "__main__":
    main()
