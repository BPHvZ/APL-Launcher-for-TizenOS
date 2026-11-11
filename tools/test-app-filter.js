#!/usr/bin/env node
"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");

const context = {
    Promise,
    APL: { t: value => value },
    tizen: {
        application: {
            getAppsInfo(success) {
                success([
                    { id: "org.omegatube.app", name: "OmegaTube", show: true },
                    { id: "org.example.unrecognized", name: "Unrecognized", show: true }
                ]);
            }
        }
    }
};
context.window = context;
vm.runInNewContext(fs.readFileSync("launcher/js/apps.js", "utf8"), context);

context.APL.loadApps().then(apps => {
    assert.deepEqual(Array.from(apps, app => app.id), ["org.omegatube.app"]);
}).catch(error => {
    console.error(error);
    process.exitCode = 1;
});
