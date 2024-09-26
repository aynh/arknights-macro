#Requires AutoHotkey v2.0

#Include Adb.ahk
#Include Error.ahk
#Include Utilities.ahk

RecruitTool() {
  tags := GetRecruitTags()
  matches := MatchRecruitTags(tags)

  if matches.Length == 0
    throw ArknightsError(Format("Found no match for tags:`n  {}", ArrayJoin(tags, ", ")))

  operator_map := GenerateOperatorMap(tags, matches)

  gui := RecruitToolGui(operator_map)
  gui.Show()
}

class RecruitToolGui extends Gui {
  __New(operator_map) {
    super.__New("AlwaysOnTop -MinimizeBox", "RecruitTool")
    operator_map_keys := this.SortedOperatorMapKeys(operator_map)

    this.AddText(, "Operator list")
    this.AddDropDownList('voperator_combobox Choose1', operator_map_keys)

    this.AddText(, "Tags combination")
    this.AddListBox('vcombination r3')

    this.AddText("ym", "Other possible operators")
    this.AddListBox('vothers r6')

    OperatorComboboxOnChange(*) {
      selected := operator_map[this["operator_combobox"].Text]
      this["combination"].Delete()
      this["combination"].Add(selected.combination)
      this["others"].Delete()
      this["others"].Add(selected.others)
    }
    this["operator_combobox"].OnEvent('Change', OperatorComboboxOnChange)
    OperatorComboboxOnChange()
  }

  SortedOperatorMapKeys(operator_map) {
    CompareOperator(a, b, *) {
      a := operator_map[a]
      b := operator_map[b]

      switch {
        ; sort them by their rarity
        ; (higher rarity first)
        case a.rarity != b.rarity:
          return b.rarity - a.rarity
          ; then sort them by their drop rate
          ; (higher drop chance first)
        case a.others.Length != b.others.Length:
          return a.others.Length - b.others.Length
          ; then sort (group) them by their combination
        case a.combination != b.combination:
          return StrCompare(ArrayJoin(a.combination), ArrayJoin(b.combination))
      }
    }

    joined := ArrayJoin([operator_map*], '|')
    sorted := Sort(joined, 'D|', CompareOperator)
    return StrSplit(sorted, '|')
  }
}

GenerateOperatorMap(tags, matches) {
  operator_map := Map()
  for match in matches {
    combination_tags := []
    for idx in match.combination
      combination_tags.Push(tags[idx])

    for idx, operator in match.operators {
      others := []
      for other_idx, other_operator in match.operators
        if other_idx != idx
          others.Push(other_operator.ToString())

      name := operator.ToString()
      rate := 1 / (others.Length + 1) * 100
      key := Format("{} ({:.0f}%)", name, rate)
      operator_map[key] := {
        combination: combination_tags,
        others: others,
        rarity: operator.rarity,
      }
    }
  }

  return operator_map
}

MatchRecruitTags(tags) {
  statiC MAX_RARITY := 6
  static MIN_RARITY := 4

  matches := []

combination_loop:
  for combination_idx in RecruitToolData.combinations {
    combination_tags := []
    for idx in combination_idx
      combination_tags.Push(tags[idx])

    robot_tag := ArrayIncludes(combination_tags, 'robot')

    combination_operators := []
    combination_min_rarity := MAX_RARITY
    for operator in RecruitToolData.operators {
      if !operator.MatchCombination(combination_tags)
        continue

      if operator.rarity < MIN_RARITY && operator.rarity != 1
        ; skip this combination if there's matching operator
        ; with rarity below min_rarity (except for the 1★)
        continue combination_loop
      else if (
        operator.rarity <= combination_min_rarity
        ; the expression below ensures that 1★ (typically robot)
        ; only get added if there's a robot tag
        && (robot_tag || operator.rarity != 1)
      ) {
        combination_min_rarity := operator.rarity
        combination_operators.Push(operator)
      }
    }

    if combination_operators.Length > 0 {
      matches.Push({ combination: combination_idx, operators: combination_operators })
    }
  }

  return matches
}

GetRecruitTags() {
  static TAGS_TOP_LEFT_XY := [
    [375, 360], [540, 360], [710, 360],
    [375, 435], [540, 435],
  ]

  static TAG_WIDTH := 145
  static TAG_HEIGHT := 45

  tags := []
read_tag_loop:
  for xy in TAGS_TOP_LEFT_XY {
retry_tag:
    loop 5 {
      tag := Adb.OCR([
        xy[1], xy[2], TAG_WIDTH, TAG_HEIGHT
      ], 5, true)
      ; filter out all those dust particles
      tag := Trim(tag, "',.:;·• ")
      ; normalize the tag
      tag := StrReplace(tag, '-', ' ')
      tag := StrLower(tag)

      if !ArrayIncludes(RecruitToolData.known_tags, tag)
        continue retry_tag

      tags.Push(tag)
      continue read_tag_loop
    }

    throw ArknightsError(Format('Got unknown tag "{}" @ index {}', tag, tags.Length + 1))
  }

  return tags
}

class Operator {
  __New(name, rarity, tags) {
    this.name := name
    this.rarity := rarity
    this.tags := tags
  }

  MatchCombination(tag_combination) {
    if this.rarity == 6 ; 6★ needs top operator tag
      && !ArrayIncludes(tag_combination, "top operator")
      return false

    for tag in tag_combination
      if !ArrayIncludes(this.tags, tag)
        return false

    return true
  }

  ToString() {
    return Format("{}★ {}", this.rarity, this.name)
  }
}

; --- everything below is automatically generated by scripts/fetch_recruit_data.py

; Last updated: 2024-07-20
class RecruitToolData {
  static combinations := [
    [1], [2], [3], [4], [5],
    [1, 2], [1, 3], [1, 4], [1, 5], [2, 3], [2, 4], [2, 5], [3, 4], [3, 5], [4, 5],
    [1, 2, 3], [1, 2, 4], [1, 2, 5], [1, 3, 4], [1, 3, 5], [1, 4, 5], [2, 3, 4], [2, 3, 5], [2, 4, 5], [3, 4, 5],
  ]

  static known_tags := [
    'aoe', 'caster', 'crowd control', 'debuff', 'defender',
    'defense', 'dp recovery', 'dps', 'fast redeploy', 'guard',
    'healing', 'medic', 'melee', 'nuker', 'ranged',
    'robot', 'senior operator', 'shift', 'slow', 'sniper',
    'specialist', 'starter', 'summon', 'support', 'supporter',
    'survival', 'top operator', 'vanguard',
  ]

  static operators := [
    Operator('"Justice Knight"', 1, ['sniper', 'robot', 'ranged', 'robot', 'support']),
    Operator('Castle-3', 1, ['guard', 'robot', 'melee', 'robot', 'support']),
    Operator('Friston-3', 1, ['defender', 'robot', 'melee', 'robot', 'defense']),
    Operator('Lancet-2', 1, ['medic', 'robot', 'ranged', 'robot', 'healing']),
    Operator('Thermal-EX', 1, ['specialist', 'robot', 'melee', 'robot', 'nuker']),
    Operator('12F', 2, ['caster', 'ranged', 'starter']),
    Operator('Durin', 2, ['caster', 'ranged', 'starter']),
    Operator('Noir Corne', 2, ['defender', 'melee', 'starter']),
    Operator('Rangers', 2, ['sniper', 'ranged', 'starter']),
    Operator('Yato', 2, ['vanguard', 'melee', 'starter']),
    Operator('Adnachiel', 3, ['sniper', 'ranged', 'dps']),
    Operator('Ansel', 3, ['medic', 'ranged', 'healing']),
    Operator('Beagle', 3, ['defender', 'melee', 'defense']),
    Operator('Catapult', 3, ['sniper', 'ranged', 'aoe']),
    Operator('Fang', 3, ['vanguard', 'melee', 'dp recovery']),
    Operator('Hibiscus', 3, ['medic', 'ranged', 'healing']),
    Operator('Kroos', 3, ['sniper', 'ranged', 'dps']),
    Operator('Lava', 3, ['caster', 'ranged', 'aoe']),
    Operator('Melantha', 3, ['guard', 'melee', 'dps', 'survival']),
    Operator('Midnight', 3, ['guard', 'melee', 'dps']),
    Operator('Orchid', 3, ['supporter', 'ranged', 'slow']),
    Operator('Plume', 3, ['vanguard', 'melee', 'dps', 'dp recovery']),
    Operator('Popukar', 3, ['guard', 'melee', 'aoe', 'survival']),
    Operator('Spot', 3, ['defender', 'melee', 'defense', 'healing']),
    Operator('Steward', 3, ['caster', 'ranged', 'dps']),
    Operator('Vanilla', 3, ['vanguard', 'melee', 'dp recovery']),
    Operator('Aciddrop', 4, ['sniper', 'ranged', 'dps']),
    Operator('Ambriel', 4, ['sniper', 'ranged', 'dps', 'slow']),
    Operator('Beehunter', 4, ['guard', 'melee', 'dps']),
    Operator('Click', 4, ['caster', 'ranged', 'dps', 'crowd control']),
    Operator('Cuora', 4, ['defender', 'melee', 'defense']),
    Operator('Cutter', 4, ['guard', 'melee', 'nuker', 'dps']),
    Operator('Dobermann', 4, ['guard', 'melee', 'dps', 'support']),
    Operator('Earthspirit', 4, ['supporter', 'ranged', 'slow']),
    Operator('Estelle', 4, ['guard', 'melee', 'aoe', 'survival']),
    Operator('Frostleaf', 4, ['guard', 'melee', 'slow', 'dps']),
    Operator('Gitano', 4, ['caster', 'ranged', 'aoe']),
    Operator('Gravel', 4, ['specialist', 'melee', 'fast redeploy', 'defense']),
    Operator('Greyy', 4, ['caster', 'ranged', 'aoe', 'slow']),
    Operator('Gum', 4, ['defender', 'melee', 'defense', 'healing']),
    Operator('Haze', 4, ['caster', 'ranged', 'dps', 'debuff']),
    Operator('Jaye', 4, ['specialist', 'melee', 'fast redeploy', 'dps']),
    Operator('Jessica', 4, ['sniper', 'ranged', 'dps', 'survival']),
    Operator('Matoimaru', 4, ['guard', 'melee', 'survival', 'dps']),
    Operator('Matterhorn', 4, ['defender', 'melee', 'defense']),
    Operator('May', 4, ['sniper', 'ranged', 'dps', 'slow']),
    Operator('Meteor', 4, ['sniper', 'ranged', 'dps', 'debuff']),
    Operator('Mousse', 4, ['guard', 'melee', 'dps']),
    Operator('Myrrh', 4, ['medic', 'ranged', 'healing']),
    Operator('Myrtle', 4, ['vanguard', 'melee', 'dp recovery', 'healing']),
    Operator('Perfumer', 4, ['medic', 'ranged', 'healing']),
    Operator('Podenco', 4, ['supporter', 'ranged', 'slow', 'healing']),
    Operator('Purestream', 4, ['medic', 'ranged', 'healing', 'support']),
    Operator('Rope', 4, ['specialist', 'melee', 'shift']),
    Operator('Scavenger', 4, ['vanguard', 'melee', 'dp recovery', 'dps']),
    Operator('Shaw', 4, ['specialist', 'melee', 'shift']),
    Operator('ShiraYuki', 4, ['sniper', 'ranged', 'aoe', 'slow']),
    Operator('Sussurro', 4, ['medic', 'ranged', 'healing']),
    Operator('Utage', 4, ['guard', 'melee', 'dps', 'survival']),
    Operator('Vermeil', 4, ['sniper', 'ranged', 'dps']),
    Operator('Vigna', 4, ['vanguard', 'melee', 'dps', 'dp recovery']),
    Operator('Andreana', 5, ['sniper', 'senior operator', 'ranged', 'dps', 'slow']),
    Operator('Asbestos', 5, ['defender', 'senior operator', 'melee', 'defense', 'dps']),
    Operator('Astesia', 5, ['guard', 'senior operator', 'melee', 'dps', 'defense']),
    Operator('Ayerscarpe', 5, ['guard', 'senior operator', 'melee', 'dps', 'aoe']),
    Operator('Beeswax', 5, ['caster', 'senior operator', 'ranged', 'aoe', 'defense']),
    Operator('Blue Poison', 5, ['sniper', 'senior operator', 'ranged', 'dps']),
    Operator('Broca', 5, ['guard', 'senior operator', 'melee', 'aoe', 'survival']),
    Operator('Chiave', 5, ['vanguard', 'senior operator', 'melee', 'dp recovery', 'dps']),
    Operator('Cliffheart', 5, ['specialist', 'senior operator', 'melee', 'shift', 'dps']),
    Operator('Croissant', 5, ['defender', 'senior operator', 'melee', 'defense', 'shift']),
    Operator('Elysium', 5, ['vanguard', 'senior operator', 'melee', 'dp recovery', 'support']),
    Operator('Executor', 5, ['sniper', 'senior operator', 'ranged', 'aoe']),
    Operator('FEater', 5, ['specialist', 'senior operator', 'melee', 'shift', 'slow']),
    Operator('Firewatch', 5, ['sniper', 'senior operator', 'ranged', 'dps', 'nuker']),
    Operator('Flint', 5, ['guard', 'senior operator', 'melee', 'dps']),
    Operator('Glaucus', 5, ['supporter', 'senior operator', 'ranged', 'slow', 'crowd control']),
    Operator('GreyThroat', 5, ['sniper', 'senior operator', 'ranged', 'dps']),
    Operator('Hung', 5, ['defender', 'senior operator', 'melee', 'defense', 'healing']),
    Operator('Indra', 5, ['guard', 'senior operator', 'melee', 'dps', 'survival']),
    Operator('Istina', 5, ['supporter', 'senior operator', 'ranged', 'slow', 'dps']),
    Operator('Leizi', 5, ['caster', 'senior operator', 'ranged', 'dps']),
    Operator('Leonhardt', 5, ['caster', 'senior operator', 'ranged', 'aoe', 'nuker']),
    Operator('Liskarm', 5, ['defender', 'senior operator', 'melee', 'defense', 'dps']),
    Operator('Manticore', 5, ['specialist', 'senior operator', 'melee', 'dps', 'survival']),
    Operator('Mayer', 5, ['supporter', 'senior operator', 'ranged', 'summon', 'crowd control']),
    Operator('Meteorite', 5, ['sniper', 'senior operator', 'ranged', 'aoe', 'debuff']),
    Operator('Nearl', 5, ['defender', 'senior operator', 'melee', 'defense', 'healing']),
    Operator('Nightmare', 5, ['caster', 'senior operator', 'ranged', 'dps', 'healing', 'slow']),
    Operator('Platinum', 5, ['sniper', 'senior operator', 'ranged', 'dps']),
    Operator('Pramanix', 5, ['supporter', 'senior operator', 'ranged', 'debuff']),
    Operator('Projekt Red', 5, ['specialist', 'senior operator', 'melee', 'fast redeploy', 'crowd control']),
    Operator('Provence', 5, ['sniper', 'senior operator', 'ranged', 'dps']),
    Operator('Ptilopsis', 5, ['medic', 'senior operator', 'ranged', 'healing', 'support']),
    Operator('Reed', 5, ['vanguard', 'senior operator', 'melee', 'dp recovery', 'dps']),
    Operator('Sesa', 5, ['sniper', 'senior operator', 'ranged', 'aoe', 'debuff']),
    Operator('Shamare', 5, ['supporter', 'senior operator', 'ranged', 'debuff']),
    Operator('Silence', 5, ['medic', 'senior operator', 'ranged', 'healing']),
    Operator('Specter', 5, ['guard', 'senior operator', 'melee', 'aoe', 'survival']),
    Operator('Swire', 5, ['guard', 'senior operator', 'melee', 'dps', 'support']),
    Operator('Texas', 5, ['vanguard', 'senior operator', 'melee', 'dp recovery', 'crowd control']),
    Operator('Tsukinogi', 5, ['supporter', 'senior operator', 'ranged', 'support', 'survival']),
    Operator('Vulcan', 5, ['defender', 'senior operator', 'melee', 'survival', 'defense', 'dps']),
    Operator('Waai Fu', 5, ['specialist', 'senior operator', 'melee', 'fast redeploy', 'debuff']),
    Operator('Warfarin', 5, ['medic', 'senior operator', 'ranged', 'healing', 'support']),
    Operator('Zima', 5, ['vanguard', 'senior operator', 'melee', 'dp recovery', 'support']),
    Operator('Aak', 6, ['specialist', 'top operator', 'ranged', 'support', 'dps']),
    Operator('Bagpipe', 6, ['vanguard', 'top operator', 'melee', 'dp recovery', 'dps']),
    Operator('Blaze', 6, ['guard', 'top operator', 'melee', 'dps', 'survival']),
    Operator('Ceobe', 6, ['caster', 'top operator', 'ranged', 'dps', 'crowd control']),
    Operator("Ch'en", 6, ['guard', 'top operator', 'melee', 'nuker', 'dps']),
    Operator('Eunectes', 6, ['defender', 'top operator', 'melee', 'dps', 'survival', 'defense']),
    Operator('Exusiai', 6, ['sniper', 'top operator', 'ranged', 'dps']),
    Operator('Hellagur', 6, ['guard', 'top operator', 'melee', 'dps', 'survival']),
    Operator('Hoshiguma', 6, ['defender', 'top operator', 'melee', 'defense', 'dps']),
    Operator('Ifrit', 6, ['caster', 'top operator', 'ranged', 'aoe', 'debuff']),
    Operator('Magallan', 6, ['supporter', 'top operator', 'ranged', 'support', 'slow', 'dps']),
    Operator('Mostima', 6, ['caster', 'top operator', 'ranged', 'aoe', 'support', 'crowd control']),
    Operator('Nightingale', 6, ['medic', 'top operator', 'ranged', 'healing', 'support']),
    Operator('Phantom', 6, ['specialist', 'top operator', 'melee', 'fast redeploy', 'crowd control', 'dps']),
    Operator('Rosa', 6, ['sniper', 'top operator', 'ranged', 'dps', 'crowd control']),
    Operator('Saria', 6, ['defender', 'top operator', 'melee', 'defense', 'healing', 'support']),
    Operator('Schwarz', 6, ['sniper', 'top operator', 'ranged', 'dps']),
    Operator('Shining', 6, ['medic', 'top operator', 'ranged', 'healing', 'support']),
    Operator('Siege', 6, ['vanguard', 'top operator', 'melee', 'dp recovery', 'dps']),
    Operator('SilverAsh', 6, ['guard', 'top operator', 'melee', 'dps', 'support']),
    Operator('Skadi', 6, ['guard', 'top operator', 'melee', 'dps', 'survival']),
    Operator('Suzuran', 6, ['supporter', 'top operator', 'ranged', 'slow', 'support', 'dps']),
    Operator('Thorns', 6, ['guard', 'top operator', 'melee', 'dps', 'defense']),
    Operator('Weedy', 6, ['specialist', 'top operator', 'melee', 'shift', 'dps', 'crowd control']),
  ]
}
