enum ProtocolActions {
  shareLoc('Share Location'),
  shareMes("Share Message"),
  startVid("Start Video Recording"),
  startVoice("Start Voice Recording"),
  startAlert("Start an Alert"),
  openScreen("Open a Decoy Screen"),
  ;

  final String identifier;

  const ProtocolActions(this.identifier);
}