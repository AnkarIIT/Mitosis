Subagent run failed before producing output.

Error:
No API key found for anthropic.

Use /login to log into a provider via OAuth or API key. See:
  C:\Users\ankar\AppData\Local\nvm\v22.22.2\node_modules\@companion-ai\feynman\node_modules\@earendil-works\pi-coding-agent\docs\providers.md
  C:\Users\ankar\AppData\Local\nvm\v22.22.2\node_modules\@companion-ai\feynman\node_modules\@earendil-works\pi-coding-agent\docs\models.md
file:///C:/Users/ankar/AppData/Local/nvm/v22.22.2/node_modules/@companion-ai/feynman/node_modules/@earendil-works/pi-coding-agent/dist/core/extensions/runner.js:358
            throw new Error(this.staleMessage);
                  ^

Error: This extension ctx is stale after session replacement or reload. Do not use a captured pi or command ctx after ctx.newSession(), ctx.fork(), ctx.switchSession(), or ctx.reload(). For newSession, fork, and switchSession, move post-replacement work into withSession and use the ctx passed to withSession. For reload, do not use the old ctx after await ctx.reload().
    at ExtensionRunner.assertActive (file:///C:/Users/ankar/AppData/Local/nvm/v22.22.2/node_modules/@companion-ai/feynman/node_modules/@earendil-works/pi-coding-agent/dist/core/extensions/runner.js:358:19)
    at get ui (file:///C:/Users/ankar/AppData/Local/nvm/v22.22.2/node_modules/@companion-ai/feynman/node_modules/@earendil-works/pi-coding-agent/dist/core/extensions/runner.js:459:24)
    at ensureIndex (C:/Users/ankar/.feynman/npm-global/node_modules/@kaiserlich-dev/pi-session-search/extensions/index.ts:52:19)

Node.js v22.22.2

Transcript: C:\Users\ankar\neet_mitos\.pi-subagents\artifacts\eb760506_worker_0_transcript.jsonl
Metadata: C:\Users\ankar\neet_mitos\.pi-subagents\artifacts\eb760506_worker_0_meta.json