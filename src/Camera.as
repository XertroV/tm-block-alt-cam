// from camera-toggle (also others)
// modified to fit our usecase

class CameraStatus {
    bool isAlt;
    bool canDrive;
    uint currCam;
    uint priorCam;

    CameraStatus(bool isAlt, bool canDrive, uint currCam, uint priorCam) {
        this.isAlt = isAlt;
        this.canDrive = canDrive;
        this.currCam = currCam == 0 || g_AlwaysUsePriorCam ? priorCam : currCam;
        this.priorCam = priorCam;
    }
    CameraStatus() {}

    string ToString() const {
        if (currCam == 0) return "None";
        return tostring(CameraType(currCam)) + " [" + tostring(CGameItemModel::EnumDefaultCam(currCam)) + "]" + (isAlt ? " (alt)" : "") + (canDrive ? " (drivable)" : "");
    }

    bool ShouldWaitAFrame() {
        return priorCam == currCam && currCam != CameraType::Cam3 && S_EnableRecenterViaToggleCurrent;
    }
}

CameraStatus@ GetCameraStatus(CGameTerminal@ gt = null) {
    if (gt is null) {
        @gt = GetGameTerminal(GetApp());
    }
    if (gt is null) return CameraStatus();
	bool alt = Dev::GetOffsetUint16(gt, 0x30) == 0x0;
	auto canDrive = Dev::GetOffsetUint32(gt, 0x60) == 0x0;
    // usually this should be current cam
	auto previousCam = Dev::GetOffsetUint32(gt, 0x34);
    // this is the camera that is going to be set when a user toggles cameras. it is more suitable for our use case in this plugin than 0x34
	auto currCam = Dev::GetOffsetUint32(gt, 0x40);
    return CameraStatus(alt, canDrive, currCam, previousCam);
}

CGameTerminal@ GetGameTerminal(CGameCtnApp@ app) {
	if (app.CurrentPlayground is null) return null;
	if (app.CurrentPlayground.GameTerminals.Length == 0) return null;
	auto gt = app.CurrentPlayground.GameTerminals[0];
    return gt;
}

void SetAltCamFlag(CGameTerminal@ gt, bool isAlt) {
    if (gt is null) return;
    Dev::SetOffset(gt, 0x30, isAlt ? 0x0 : 0x1);
}

void SetDrivableCamFlag(CGameTerminal@ gt, bool canDrive) {
    if (gt is null) return;
    Dev::SetOffset(gt, 0x60, canDrive ? 0x0 : 0x1);
}

// crashes on 0x8, 0x9, and 0x1e or greater
// 3,4,5,6 are some kind of default cams where you need to toggle free cam drivable to drive
enum CameraType {
    FreeCam = 0x2,
    WeirdDefault = 0x5,
    Intro7Mb = 0x7,
    Intro10Mb = 0x10,
    FreeCam2 = 0x11,
    Cam1 = 0x12,
    Cam2 = 0x13,
    Cam3 = 0x14,
    Backwards = 0x15,
    Intro16Mb = 0x16,
    // same repeated up to 0x1d
    // Intro1dMb = 0x1d,
}
