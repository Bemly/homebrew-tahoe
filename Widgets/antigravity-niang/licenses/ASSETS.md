# 素材来源与使用许可

## Gemini 娘角色设定

Gemini 娘是围绕 Gemini 创作的同人形象。该角色形象及本挂件与 Google 官方无关，均未获得 Google 官方认可或授权。

感谢 B 站创作者 **ZipZipPipe** 创作 Gemini 娘的原形象。根据项目维护者提供的信息，原形象采用**知识共享署名—非商业性使用—相同方式共享 4.0 国际许可协议（CC BY-NC-SA 4.0）**。此处署名及许可说明针对原角色形象。[作者 B 站空间](https://space.bilibili.com/4168597) · [协议中文摘要](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.zh-hans) · [许可条款全文](https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode)

## 随挂件分发的 Q 版立绘

默认挂件使用一张网络流传的 Q 版插画，由 AI 依照 ZipZipPipe 创作的 Gemini 娘形象改编而成。这张图的制作者、首发页面和公开分发许可仍待确认。

- [默认立绘](gemini-widget.png)在网络图片的基础上做了透明抠图，并用 AI 补全右侧发髻和发梢，参照原角色调整了发型、蓝紫渐变发色、金边四芒星头饰和露肩服装。
- [插件图标](antigravity-plugin/logo.png)由默认立绘等比缩小并添加透明留白，用于 Antigravity 的 Customizations 面板。[随插件分发的图标声明](antigravity-plugin/ICON-NOTICE.md)
- [音乐律动预览](音乐律动-墨镜预览.png)使用同一张立绘，墨镜和音箱由挂件程序绘制并叠加。

如果你是这张插画的制作者、权利人，或知道原始出处，欢迎提供作品链接、补充署名，或联系维护者更换、移除相关图片。[项目 Issues](https://github.com/CosmicShinosawa/agy-gemini-niang-widget/issues)

## 音效与语录

- 原版加响的[按压](assets/press.wav)、[松开](assets/release.wav)，星铃的[按压](assets/star-bell-press.wav)、[松开](assets/star-bell-release.wav)，以及软弹果冻的[按压](assets/soft-bounce-press.wav)、[松开](assets/soft-bounce-release.wav)均由本项目合成，按 [MIT 许可](LICENSE) 分发。
- [默认语录](assets/quotes.json)共 45 条，由维护者与 Gemini 在已有语录基础上选编、增写。其中 18 条与 GPT-Niang 1.3.5 内置语录文字一致，包括由 DSH 小鲸鱼传入的 7 条。感谢两边的台词作者。[GPT-Niang 语录](https://github.com/T7moris/GPT-Niang/blob/main/gpt-niang-usage/assets/quotes.json) · [DSH 七条原文及许可](licenses/upstream-quotes.txt)

## 上游代码

感谢 **T7moris 和 GPT-Niang 贡献者**提供 Windows 挂件、音乐律动、语录和音频实现，感谢 **MeteorNOX** 的 DSH 小鲸鱼提供气泡序列与交互设计。两份 MIT 版权及许可文本随仓库保留。[GPT-Niang 许可](licenses/GPT-Niang-MIT.txt) · [DSH 小鲸鱼许可](licenses/DSH-Whale-MIT.txt)

## 开发与分发声明

本项目以 **GPT-Niang** 的 Windows 挂件为基础，参考 **dsh-whale-widget** 的气泡与吸附交互。维护者 **CosmicShinosawa** 最初在 **GPT-6.2 Astra** 的协助下完成 Antigravity 移植，让挂件跟随宿主窗口、读取本机额度，并在气泡中按模型分组显示；后续由 **Gemini 4 Neon** 接续维护与迭代发布。

本仓库及挂件发布包均未收录 Google、OpenAI 等公司的闭源商业代码、非公开专有源码或从其产品中提取的专有二进制资产。项目代码按 MIT 许可分发，上游代码保留各自的版权声明。角色设定、Q 版插画、音效和语录的来源及使用条件见本页各节。[项目代码许可证](LICENSE)
