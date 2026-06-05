(function () {
    "use strict";

    var configuredUser = "__ARCH_LOGIN_USER__";
    var configuredSession = "__ARCH_LOGIN_SESSION__";
    var selectedSession = configuredSession || "bspwm";
    var authenticating = false;

    var timeLabel = document.getElementById("timeLabel");
    var dateLabel = document.getElementById("dateLabel");
    var hostLabel = document.getElementById("hostLabel");
    var username = document.getElementById("username");
    var password = document.getElementById("password");
    var loginForm = document.getElementById("loginForm");
    var loginButton = document.getElementById("loginButton");
    var message = document.getElementById("message");
    var sessionLabel = document.getElementById("sessionLabel");
    var sessionButton = document.getElementById("sessionButton");
    var restartButton = document.getElementById("restartButton");
    var powerButton = document.getElementById("powerButton");
    var togglePassword = document.getElementById("togglePassword");

    function setMessage(text) {
        message.textContent = text || "";
    }

    function updateClock() {
        var now = new Date();
        timeLabel.textContent = now.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
        dateLabel.textContent = now.toLocaleDateString([], { weekday: "long", month: "long", day: "numeric" });
    }

    function setHost() {
        if (window.lightdm && lightdm.hostname) {
            hostLabel.textContent = lightdm.hostname;
        }
    }

    function sessionName(key) {
        if (!window.lightdm || !lightdm.sessions) {
            return key.toUpperCase();
        }

        for (var i = 0; i < lightdm.sessions.length; i += 1) {
            if (lightdm.sessions[i].key === key) {
                return lightdm.sessions[i].name || key;
            }
        }

        return key;
    }

    function setSession(key) {
        selectedSession = key || configuredSession || "bspwm";
        sessionLabel.textContent = sessionName(selectedSession);
    }

    function cycleSession() {
        if (!window.lightdm || !lightdm.sessions || lightdm.sessions.length === 0) {
            return;
        }

        var index = 0;
        for (var i = 0; i < lightdm.sessions.length; i += 1) {
            if (lightdm.sessions[i].key === selectedSession) {
                index = i;
                break;
            }
        }

        var next = lightdm.sessions[(index + 1) % lightdm.sessions.length];
        setSession(next.key);
    }

    function startAuthentication() {
        if (!window.lightdm) {
            setMessage("LightDM API is not available");
            return;
        }

        if (authenticating && lightdm.cancel_authentication) {
            lightdm.cancel_authentication();
        }

        authenticating = true;
        loginButton.disabled = true;
        setMessage("Checking identity...");
        lightdm.authenticate(configuredUser);
    }

    function completeLogin() {
        if (!window.lightdm || !lightdm.is_authenticated) {
            loginButton.disabled = false;
            authenticating = false;
            password.value = "";
            password.focus();
            setMessage("Authentication failed");
            return;
        }

        setMessage("Starting session...");
        lightdm.start_session(selectedSession);
    }

    window.show_prompt = function () {
        if (!authenticating) {
            return;
        }
        lightdm.respond(password.value);
    };

    window.show_message = function (text) {
        setMessage(text);
    };

    window.show_error = function (text) {
        setMessage(text || "Authentication error");
    };

    window.authentication_complete = completeLogin;

    loginForm.addEventListener("submit", function (event) {
        event.preventDefault();
        username.value = configuredUser;
        startAuthentication();
    });

    togglePassword.addEventListener("click", function () {
        var showing = password.type === "text";
        password.type = showing ? "password" : "text";
        togglePassword.querySelector(".material-symbols-outlined").textContent = showing ? "visibility_off" : "visibility";
        password.focus();
    });

    sessionButton.addEventListener("click", cycleSession);

    restartButton.addEventListener("click", function () {
        if (window.lightdm) {
            lightdm.restart();
        }
    });

    powerButton.addEventListener("click", function () {
        if (window.lightdm) {
            lightdm.shutdown();
        }
    });

    updateClock();
    setInterval(updateClock, 1000);
    setHost();
    setSession(configuredSession);
    username.value = configuredUser;
    password.focus();
}());
