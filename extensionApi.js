Subject = class {
    constructor() {
        this.observers = [];
    }

    addListener(fn) {
        this.observers.push(fn)
    }

    removeListener(fnToRemove) {
        this.observers = this.observers.filter(fn => {
            if (fn != fnToRemove) {
                return fn;
            }
        })
    }

    fire(...args) {
        let results = [];
        this.observers.forEach(fn => {
            // fn.call();
            results.push(fn(...args));
        })
        return results;
    }
}

Browser = class {

    constructor(runtime, tabs, webRequest, cookies) {
        this.storage = new Storage;
        this.runtime = runtime;
        this.tabs = tabs;
        this.webRequest = webRequest;
        this.cookies = cookies;
        this.browserAction = new BrowserAction;
    }

}

Storage = class {

    constructor() {
        this.sync = new SyncStorage(this);
        this.onChanged = new Subject();
    }
}

SyncStorage = class {

    constructor(storage) {
        this.data = {};
        this.stringify();
        this.onChanged = new Subject();
        this.storage = storage
    }

    set(object, completion) {
        let changes = {};
        console.log("SETTING:", object);
        let newData = JSON.parse(this.data);
        for (const key in object) {
            if (Object.hasOwnProperty.call(object, key)) {
                const element = object[key];
                newData[key] = element;
                changes[key] = {
                    newValue: element
                }
            }
        }
        this.data = newData;
        this.stringify();
        this.onChanged.fire(changes);
        this.storage.onChanged.fire(changes);

        completion();
    }

    get(object, completion) {
        let result = {}
        for (const key in object) {
            result[key] = this.data[key] ?? object[key];
        }
        completion(result);
    }

    stringify() {
        this.data = JSON.stringify(this.data);
    }
}

Runtime = class {
    constructor(manifest) {
        this.onInstalled = new Subject();
        this.lastError = null;
        this.manifest = manifest;
    }

    openOptionsPage() {

    }

    getManifest() {
        return this.manifest;
    }
}

Tabs = class {
    constructor(tabs) { //tabs is array
        this.onActivated = new Subject();
        this.onUpdated = new Subject();
        this.tabs = tabs;
    }

    get(tabId, completion) {
        completion(this.tabs[0]); //its always 1 currently
    }

    executeScript(tabId, script, completion) {
        //todo: implement completion
        //todo: get path from script properly
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.executeScriptMessageHandler) {
            window.webkit.messageHandlers.executeScriptMessageHandler.postMessage({
                "message": JSON.stringify(script)
            });
        }
    }
}

Tab = class {
    constructor(url) {
        this.url = url;
    }
}

WebRequest = class {
    constructor() {
        // implement all these - call from native
        //https://developer.apple.com/documentation/webkit/wknavigationdelegate?language=objc
        //https://stackoverflow.com/questions/40133512/intercept-request-with-wkwebview%C2%A0

        // override loadRequest method - https://stackoverflow.com/questions/28984212/how-to-add-http-headers-in-request-globally-for-ios-in-swift
        this.onBeforeRequest = new Subject();
        this.onBeforeSendHeaders = new Subject();
        this.OnBeforeSendHeadersOptions = {};
        this.onCompleted = new Subject();
        this.onInstalled = new Subject();
    }
}

BrowserAction = class {
    constructor() {

    }

    setBadgeBackgroundColor() {}
    setBadgeText(){}
}

Cookies = class {
    constructor(cookies) {
        this.cookies = cookies;
    }

    getAll(options, completion) {
        debugger;
        let cookies = this.cookies.filter(c => {
            for (const key in options) {
                if (Object.hasOwnProperty.call(options, key)) {
                    const value = options[key];
                    if (c[key] !== value) {
                        return false;
                    }
                }
            }

            return true;
        });
        completion(cookies);
    }

    remove(cookie) {
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.removeCookieMessageHandler) {
            window.webkit.messageHandlers.removeCookieMessageHandler.postMessage({
                "message": JSON.stringify(cookie)
            });
        }
    }
}

HTTPCookie = class {
    constructor(name, value, domain, secure, path) {

    }
}
