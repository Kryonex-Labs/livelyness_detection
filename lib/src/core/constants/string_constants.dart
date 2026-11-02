// ignore_for_file: library_private_types_in_public_api

class StringConstants {
  static _LabelStrings label = _LabelStrings();
  static _ButtonStrings button = _ButtonStrings();
}

class _LabelStrings {
  final String livelyNessDetection = "Verify it's really you";
  final String goodLighting = "Good Lighting";
  final String lookStraight = "Look Straight";
  final String goodLightingSubText =
      "Make sure you are in a well lit area and both ears are uncovered";
  final String lookStraightSubText =
      "Hold your phone at eye level and look straight to the camera";
  final String infoSubText =
      "Follow the on-screen prompts to confirm you're a real, live person.";
}

class _ButtonStrings {
  final String start = "Begin Verification";
}
