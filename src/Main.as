const string PluginName = Meta::ExecutingPlugin().Name;
const string MenuIconColor = "\\$f5d";
const string PluginIcon = Icons::Cogs;
const string MenuTitle = MenuIconColor + PluginIcon + "\\$z " + PluginName;

void Main() {
    yield(17);
    // This can be run in a coro with GameLoop or MainLoop contextes with okay results, but camera movement is not sooth for a frame or two when switching (sometimes).
    // Using a hook solves this so it's seamless.
    HookAfterSetAlt.Apply();
}

void CheckCameras(CGameCtnApp@ app) {
    auto gt = GetGameTerminal(app);
    if (gt is null) return;
    auto camStatus = GetCameraStatus();
    if (camStatus.currCam == CameraType::Cam1) {
        CheckSetAlt(gt, S_Cam1Auto, camStatus);
    } else if (camStatus.currCam == CameraType::Cam2) {
        CheckSetAlt(gt, S_Cam2Auto, camStatus);
    } else if (camStatus.currCam == CameraType::Cam3) {
        CheckSetAlt(gt, S_Cam3Auto, camStatus);
    }
}

void CheckSetAlt(CGameTerminal@ gt, CameraAutoToggleChoice choice, CameraStatus@ cs) {
    switch (choice) {
        case CameraAutoToggleChoice::Do_Nothing:
            break;
        case CameraAutoToggleChoice::Always_Alt:
            // if (cs.isAlt) break;
            dev_trace("set alt cam flag");
            SetAltCamFlag(gt, true);
            break;
        case CameraAutoToggleChoice::Never_Alt:
            // if (!cs.isAlt) break;
            dev_trace("unset alt cam flag");
            SetAltCamFlag(gt, false);
            break;
    }
}

FunctionHookHelper@ HookAfterSetAlt = FunctionHookHelper(
    // v call that sets the alt cam
    "E8 ?? ?? 00 00 8B D6 48 8B CB E8",
    //               ^ mov         ^ another call / to do with choice of cam
    // we don't *need* two ?? in the pattern (replacing 2nd with 00 works). However, 2x ??s is still unique, and makes the pattern a little more resilient to small changes in the exe code.
    // "E8 ?? 00 00 00 8B D6 48 8B CB E8",
    0, 0, "OnSetAltCamFlag", Dev::PushRegisters::Basic
);

void OnSetAltCamFlag(CGameTerminal@ rbx) {
    if (rbx is null) {
        warn("Unexpected: rbx is null in OnSetAltCamFlag");
        return;
    }
    auto camStatus = GetCameraStatus();
    if (camStatus.currCam == CameraType::Cam1) {
        CheckSetAlt(rbx, S_Cam1Auto, camStatus);
    } else if (camStatus.currCam == CameraType::Cam2) {
        CheckSetAlt(rbx, S_Cam2Auto, camStatus);
    } else if (camStatus.currCam == CameraType::Cam3) {
        CheckSetAlt(rbx, S_Cam3Auto, camStatus);
    }
}



void dev_trace(const string &in msg) {
#if DEV
    trace('[' + Time::Now + '] ' + msg);
#endif
}

void dev_warn(const string &in msg) {
#if DEV
    warn(msg);
#endif
}
