enum CameraAutoToggleChoice {
    Do_Nothing,
    Always_Alt,
    Never_Alt
}

[Setting hidden]
bool S_Enabled = true;

[Setting hidden]
CameraAutoToggleChoice S_Cam1Auto = CameraAutoToggleChoice::Do_Nothing;

[Setting hidden]
CameraAutoToggleChoice S_Cam2Auto = CameraAutoToggleChoice::Do_Nothing;

[Setting hidden]
CameraAutoToggleChoice S_Cam3Auto = CameraAutoToggleChoice::Do_Nothing;

[SettingsTab name="Block Alt Cams"]
void R_S_AutoToggles() {
    bool wasEnabled = S_Enabled;
    S_Enabled = UI::Checkbox("Enabled", S_Enabled);
    if (wasEnabled != S_Enabled) HookAfterSetAlt.SetApplied(S_Enabled);
    UI::SeparatorText("Cam 1");
    UI::TextWrapped("When changing to Cam 1, set the alt cam?");
    S_Cam1Auto = Combo_CamChoice("Cam 1", S_Cam1Auto);
    UI::SeparatorText("Cam 2");
    UI::TextWrapped("When changing to Cam 2, set the alt cam?");
    S_Cam2Auto = Combo_CamChoice("Cam 2", S_Cam2Auto);
    UI::SeparatorText("Cam 3");
    UI::TextWrapped("When changing to Cam 3, set the alt cam?");
    S_Cam3Auto = Combo_CamChoice("Cam 3", S_Cam3Auto);
}

CameraAutoToggleChoice Combo_CamChoice(const string &in label, CameraAutoToggleChoice val) {
    if (UI::BeginCombo(label, tostring(val))) {
        if (UI::Selectable("Do Nothing (Toggles like normal)", val == CameraAutoToggleChoice::Do_Nothing)) {
            val = CameraAutoToggleChoice::Do_Nothing;
        }
        if (UI::Selectable("Always Alt", val == CameraAutoToggleChoice::Always_Alt)) {
            val = CameraAutoToggleChoice::Always_Alt;
        }
        if (UI::Selectable("Never Alt", val == CameraAutoToggleChoice::Never_Alt)) {
            val = CameraAutoToggleChoice::Never_Alt;
        }
        UI::EndCombo();
    }
    return val;
}
