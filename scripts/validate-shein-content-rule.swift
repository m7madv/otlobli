#!/usr/bin/env swift

import Foundation
import WebKit

let ruleIdentifier = "com.otlobli.shein.raw-js-prefetch-block.v1.ci-\(UUID().uuidString.lowercased())"
let encodedRule = #"""
[
  {
    "trigger": {
      "url-filter": "^https://sheinm\\.ltwebstatic\\.com/pwa_dist/assets/.*\\.js",
      "url-filter-is-case-sensitive": true,
      "resource-type": ["raw"]
    },
    "action": {
      "type": "block"
    }
  }
]
"""#

guard let jsonData = encodedRule.data(using: .utf8),
      let rules = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]],
      rules.count == 1,
      let trigger = rules[0]["trigger"] as? [String: Any],
      trigger["resource-type"] as? [String] == ["raw"],
      trigger["url-filter-is-case-sensitive"] as? Bool == true else {
    fputs("Static SHEIN content-rule JSON validation failed.\n", stderr)
    exit(1)
}

var completed = false
var compiledRule: WKContentRuleList?
var compilationError: Error?
WKContentRuleListStore.default().compileContentRuleList(
    forIdentifier: ruleIdentifier,
    encodedContentRuleList: encodedRule
) { ruleList, error in
    compiledRule = ruleList
    compilationError = error
    completed = true
}

let deadline = Date().addingTimeInterval(30)
while !completed && Date() < deadline {
    RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
}

guard completed, compiledRule != nil, compilationError == nil else {
    fputs("WebKit content-rule compilation failed: \(String(describing: compilationError))\n", stderr)
    exit(1)
}

print("WebKit compiled SHEIN raw-only content rule: \(ruleIdentifier)")
