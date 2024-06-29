const string PluginName = Meta::ExecutingPlugin().Name;
const string MenuIconColor = "\\$fd2";
const string PluginIcon = Icons::Ban + Icons::CameraRetro;
const string MenuTitle = MenuIconColor + PluginIcon + "\\$z " + PluginName;

void Main() {
    yield(17);
    if (!S_Enabled) return;
    // This can be run in a coro with GameLoop or MainLoop contextes with okay results, but camera movement is not sooth for a frame or two when switching (sometimes).
    // Using a hook solves this so it's seamless.
    HookAfterSetAlt.Apply();
    if (!HookAfterSetAlt.IsApplied()) return;
    // Another plugin can change the cameras tho (e.g., camera toggle), so we need to check every once in a while anyway.
    startnew(CheckCamerasLoop).WithRunContext(Meta::RunContext::GameLoop);
}

bool g_CamCheckShouldWaitIfSameCam = false;

void CheckCamerasLoop() {
    while (true) {
        yield(3);
        auto app = GetApp();
        if (app is null) continue;
        CheckCameras(app);
    }
}

void OnEnabled() {
    if (S_Enabled) HookAfterSetAlt.Apply();
}

void OnDisabled() {
    CheckUnhookAllRegisteredHooks();
}
void OnDestroyed() {
    CheckUnhookAllRegisteredHooks();
}

void RenderMenu() {
    if (UI::BeginMenu(MenuTitle)) {
        R_S_AutoToggles();
        UI::EndMenu();
    }
}

void CheckCameras(CGameCtnApp@ app) {
    auto gt = GetGameTerminal(app);
    if (gt is null) return;
    OnSetAltCamFlag(gt);
}

void CheckSetAlt(CGameTerminal@ gt, CameraAutoToggleChoice choice, CameraStatus@ cs) {
    // dev_trace("CheckSetAlt: " + choice + " " + tostring(cs));
    switch (choice) {
        case CameraAutoToggleChoice::Do_Nothing:
            break;
        case CameraAutoToggleChoice::Always_Alt:
            if (cs.isAlt) break;
            dev_trace("set alt cam flag");
            if (cs.ShouldWaitAFrame()) {
                startnew(CoroutineFuncUserdataUint64(SetAltCamNextFrame), uint64(1));
            } else {
                SetAltCamFlag(gt, true);
            }
            break;
        case CameraAutoToggleChoice::Never_Alt:
            if (!cs.isAlt) break;
            dev_trace("unset alt cam flag");
            if (cs.ShouldWaitAFrame()) {
                startnew(CoroutineFuncUserdataUint64(SetAltCamNextFrame), uint64(0));
            } else {
                SetAltCamFlag(gt, false);
            }
            break;
    }
}

// isAlt: 0 for false, 1 for true
void SetAltCamNextFrame(uint64 isAlt) {
    yield();
    auto gt = GetGameTerminal(GetApp());
    if (gt is null) return;
    SetAltCamFlag(gt, isAlt > 0);
}

FunctionHookHelper@ HookAfterSetAlt = FunctionHookHelper(
    // v call that sets the alt cam               v mov rcx,[rbx+28] -- rbx+28 functions as a check that offsets haven't changed. If we can't find this pattern, we don't want to do anything.
    "E8 ?? ?? 00 00 8B D6 48 8B CB E8 ?? FF FF FF 48 8B 4B 28",
    //               ^ mov         ^ another call / to do with choice of cam
    // we don't *need* two ?? in the pattern (replacing 2nd with 00 works). However, 2x ??s is still unique, and makes the pattern a little more resilient to small changes in the exe code.
    // "E8 ?? 00 00 00 8B D6 48 8B CB E8",
    // "E8 ?? ?? 00 00 8B D6 48 8B CB E8",
    0, 0, "OnSetAltCamFlag", Dev::PushRegisters::Basic
);

void OnSetAltCamFlag(CGameTerminal@ rbx) {
    if (rbx is null) {
        warn("Unexpected: rbx is null in OnSetAltCamFlag");
        return;
    }
    auto camStatus = GetCameraStatus(rbx);
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
