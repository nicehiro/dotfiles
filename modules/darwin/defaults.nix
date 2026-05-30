{ ... }:

{
  system.defaults = {
    finder.FXPreferredViewStyle = "clmv";
    finder.AppleShowAllExtensions = true;
    finder.AppleShowAllFiles = true;
    finder.NewWindowTarget = "Documents";
    finder.ShowPathbar = true;
    finder.ShowStatusBar = true;
    finder.FXDefaultSearchScope = "SCcf";

    controlcenter.BatteryShowPercentage = true;

    menuExtraClock.Show24Hour = true;
    menuExtraClock.ShowAMPM = false;
    menuExtraClock.ShowDate = 2;
    menuExtraClock.ShowDayOfMonth = false;

    loginwindow.GuestEnabled = false;

    NSGlobalDomain.AppleICUForce24HourTime = true;
    NSGlobalDomain.KeyRepeat = 2;
    NSGlobalDomain.ApplePressAndHoldEnabled = false;

    trackpad.Clicking = true;
    trackpad.Dragging = true;
    trackpad.TrackpadThreeFingerDrag = true;
  };
}
