#Requires AutoHotkey v2.0

#Include Adb.ahk
#Include Helper.ahk

class RecruitToolConst {
  statiC MAX_RARITY := 6
  static MIN_RARITY := 3

  static TAGS_TOP_LEFT_XY := [
    [375, 360], [540, 360], [710, 360],
    [375, 435], [540, 435],
  ]

  static TAG_WIDTH := 145
  static TAG_HEIGHT := 45
}

RecruitTool() {
  tags := GetRecruitTags()
  matches := MatchRecruitTags(tags)

  if matches.Length == 0
    return

  operator_map := BuildOperatorMap(tags, matches)
  operator_map_keys := SortedOperatorMapKeys(operator_map)

  _gui := Gui("AlwaysOnTop -MinimizeBox", "RecruitTool")

  _gui.AddText(, "Operator list")
  _gui_operator_list := _gui.AddDropDownList('Choose1', operator_map_keys)

  _gui.AddText(, "Tags combination")
  _gui_tags_combination := _gui.AddListBox('r3')
  UpdateTagsCombination(*) {
    _gui_tags_combination.Delete()
    _gui_tags_combination.Add(operator_map[_gui_operator_list.Text].combination)
  }
  _gui_operator_list.OnEvent('Change', UpdateTagsCombination)
  UpdateTagsCombination()

  _gui.AddText("ym", "Other possible operators")
  _gui_other_possible_operators := _gui.AddListBox('r6')
  UpdateOtherPossibleOperators(*) {
    _gui_other_possible_operators.Delete()
    _gui_other_possible_operators.Add(operator_map[_gui_operator_list.Text].others)
  }
  _gui_operator_list.OnEvent('Change', UpdateOtherPossibleOperators)
  UpdateOtherPossibleOperators()

  _gui.Show()
}

SortedOperatorMapKeys(operator_map) {
  CompareOperator(a, b, *) {
    a := operator_map[a]
    b := operator_map[b]

    ; sort them by their rarity
    ; (higher rarity first)
    if a.rarity != b.rarity
      return b.rarity - a.rarity
    ; then sort them by their drop rate
    ; (higher drop chance first)
    else if a.others.Length != b.others.Length
      return a.others.Length - b.others.Length
    ; then sort (group) them by their combination
    else if a.combination != b.combination
      return StrCompare(ArrayJoin(a.combination), ArrayJoin(b.combination))
  }

  joined := ArrayJoin([operator_map*], '|')
  sorted := Sort(joined, 'D|', CompareOperator)
  return StrSplit(sorted, '|')
}

BuildOperatorMap(tags, matches) {
  operator_map := Map()
  for match in matches {
    combination_tags := []
    for idx in match.combination
      combination_tags.Push tags[idx]

    for idx, operator in match.operators {
      others := []
      for other_idx, other_operator in match.operators
        if other_idx != idx
          others.Push other_operator.ToString()

      operator_map.Set(
        operator.ToString(), {
          combination: combination_tags,
          others: others,
          rarity: operator.rarity,
        }
      )
    }
  }

  for operator_name in operator_map {
    operator_data := operator_map.Delete(operator_name)
    operator_map.Set(
      Format("{} ({:.0f}%)", operator_name, 1 / (operator_data.others.Length + 1) * 100),
      operator_data
    )
  }

  return operator_map
}

MatchRecruitTags(tags) {
  matches := []

combination_loop:
  for combination_idx in RecruitToolData.combinations {
    combination_tags := []
    for idx in combination_idx
      combination_tags.Push tags[idx]

    robot_tag := ArrayIncludes(combination_tags, 'robot')

    combination_operators := []
    combination_min_rarity := RecruitToolConst.MAX_RARITY
    for operator in RecruitToolData.operators
      if operator.MatchCombination(combination_tags) {
        if (
          operator.rarity < RecruitToolConst.MIN_RARITY
          && operator.rarity != 1
        ) {
          ; skip this combination if there's an operator
          ; with rarity below the min_rarity constant
          ; (except for the robots)
          continue combination_loop
        } else if (
          operator.rarity <= combination_min_rarity
          ; the expression below ensures that 1★ (typically robot)
          ; only get added if there's a robot tag
          && (robot_tag || operator.rarity != 1)
        ) {
          combination_min_rarity := operator.rarity
          combination_operators.Push operator
        }
      }

    if combination_operators.Length > 0 {
      matches.Push({ combination: combination_idx, operators: combination_operators })
    }
  }

  return matches
}

GetRecruitTags() {
  tags := []
  for xy in RecruitToolConst.TAGS_TOP_LEFT_XY {
    tag := Adb.OCR_Region(
      [
        xy[1], xy[2],
        RecruitToolConst.TAG_WIDTH, RecruitToolConst.TAG_HEIGHT
      ], 2.5
    )
    ; alter the tag a little for consistency with aceship data
    tag := StrReplace(tag, '-', ' ')
    tag := StrLower(tag)
    tags.Push(tag)
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

; Last updated: 2024-06-04
class RecruitToolData {
  static combinations := [
    [1], [2], [3], [4], [5],
    [1, 2], [1, 3], [1, 4], [1, 5], [2, 3], [2, 4], [2, 5], [3, 4], [3, 5], [4, 5],
    [1, 2, 3], [1, 2, 4], [1, 2, 5], [1, 3, 4], [1, 3, 5], [1, 4, 5], [2, 3, 4], [2, 3, 5], [2, 4, 5], [3, 4, 5],
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
