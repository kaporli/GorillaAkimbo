// Gorilla Grip: with Gorilla Arms equipped, SMGs and shotguns can be dual-wielded (Double Trouble still required).
// Without Gorilla Arms, dual-wielding stays vanilla (pistols and revolvers only).
module GorillaGrip

import Codeware.Localization.*

// Weapon types the reinforced grip adds to dual-wielding.
public func IsGripWeaponType(type: gamedataItemType) -> Bool {
  return Equals(type, gamedataItemType.Wea_SubmachineGun)
    || Equals(type, gamedataItemType.Wea_Shotgun)
    || Equals(type, gamedataItemType.Wea_ShotgunDual);
}

public func HasGorillaArms(owner: wref<GameObject>) -> Bool {
  let player = owner as PlayerPuppet;
  if !IsDefined(player) {
    return false;
  }
  let data = EquipmentSystem.GetData(player);
  if !IsDefined(data) {
    return false;
  }
  let area = gamedataEquipmentArea.ArmsCW;
  let count = data.GetNumberOfSlots(area);
  let i = 0;
  while i < count {
    let id = data.GetItemInEquipSlot(area, i);
    if ItemID.IsValid(id) && Equals(RPGManager.GetItemType(id), gamedataItemType.Cyb_StrongArms) {
      return true;
    }
    i += 1;
  }
  return false;
}

// At load: give SMGs and shotguns the game's dual-wield tag, and add the tooltip line to Gorilla Arms.
class GorillaGripTweak extends ScriptableTweak {
  protected func OnApply() {
    for record in TweakDBInterface.GetRecords(n"Item_Record") {
      let item = record as Item_Record;
      let type = gamedataItemType.Invalid;
      if IsDefined(item) && IsDefined(item.ItemType()) {
        type = item.ItemType().Type();
      }
      let id = record.GetID();
      if IsGripWeaponType(type) {
        let tags = TweakDBInterface.GetCNameArray(id + t".tags");
        if !ArrayContains(tags, n"DualWield") {
          ArrayPush(tags, n"DualWield");
          TweakDBManager.SetFlat(id + t".tags", tags);
          TweakDBManager.UpdateRecord(id);
        }
      } else {
        if Equals(type, gamedataItemType.Cyb_StrongArms) {
          let onEquip = TweakDBInterface.GetForeignKeyArray(id + t".OnEquip");
          if !ArrayContains(onEquip, t"GorillaGrip.GripPackage") {
            ArrayPush(onEquip, t"GorillaGrip.GripPackage");
            TweakDBManager.SetFlat(id + t".OnEquip", onEquip);
            TweakDBManager.UpdateRecord(id);
          }
        }
      }
    }
  }
}

// SMGs and shotguns only count as dual-wieldable while Gorilla Arms are equipped.
@wrapMethod(gameItemData)
public func CanDualWield(owner: wref<GameObject>) -> Bool {
  let result = wrappedMethod(owner);
  if result && IsGripWeaponType(RPGManager.GetItemType(this.GetID())) && !HasGorillaArms(owner) {
    return false;
  }
  return result;
}

// Double Trouble's weapon box (the red "Only affects ..." line at the top of the tooltip) gets a second line.
@wrapMethod(PerkDisplayTooltipController)
private func PerkWeaponGroupTypeToText(type: gamedataPerkWeaponGroupType) -> String {
  let text = wrappedMethod(type);
  if Equals(type, gamedataPerkWeaponGroupType.CoolDualWieldingPerkWeaponGroup) {
    text = GetLocalizedText(text) + "\n" + GetLocalizedTextByKey(n"GorillaGrip-PerkNote");
  }
  return text;
}

public class EnglishPackage extends ModLocalizationPackage {
  protected func DefineTexts() {
    this.Text("GorillaGrip-ArmsLine", "Reinforced grip actuators steady SMGs and shotguns one-handed: with Double Trouble, they can be dual-wielded.");
    this.Text("GorillaGrip-PerkNote", "With Gorilla Arms: also SMGs and Shotguns");
  }
}

public class LocalizationProvider extends ModLocalizationProvider {
  public func GetPackage(language: CName) -> ref<ModLocalizationPackage> {
    switch language {
      case n"en-us": return new EnglishPackage();
      default: return null;
    }
  }

  public func GetFallback() -> CName {
    return n"en-us";
  }
}
