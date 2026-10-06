# BIAMP AD BLOCKER

> Adware-Malware Blocker compatible with manifest V3 rule-based and static, meaning it won't send data anywhere using [StevenBlack/hosts](https://raw.githubusercontent.com/StevenBlack/hosts/refs/heads/master/hosts) hosts in order to block ads.

![Json](https://img.shields.io/badge/Json-yellow.svg)
![Python](https://img.shields.io/badge/Python-3.8%2B-blue.svg)
![License](https://img.shields.io/badge/License-Apache2.0-red.svg)
![Status](https://img.shields.io/badge/Project-Active-brightgreen.svg)

## Table of Contents

- [Overview](#overview)
- [Project Structure](#project-structure)
- [Rule Structure](#rule-structure)
- [How to run](#how-to-run)
- [License](#license)

## OVERVIEW

This extension is meant to block ads according to the new manifest V3. It works by using the adware-malware dns domains, where we add the character "^" to json files, each domain with it's id, priority and action (all adware-malware dns domains have priority of 1, which is a low priority, but it wouldn't matter since they all have the same action which is block which gives them the same order of priority). It's safer than other extensions not only beacuse of the transperency of the code, but because it uses static rules meaning the code will never reach outside your browser or send data anywhere and it also follows the latest Manifest Version (V3) meaning it will be supported for a long period of time and offers better privacy and security compare to Manifest V2, where code could be hosted remotely and running long-lived background pages even when the extension wasn't running. The structures of how it works will be presented bellow.

## Project Structure


```mermaid
graph TD;
    A[data_fetcher.py] --> B[ad-domains.txt];
    B --> C[rules_creator.py];
    C --> D[rules_{number}.json];
    D --> E[manifest.json];
```

## Rule Structure

```json
{
    "id": incrementing integer,
    "priority": 1,
    "action": {
      "type": "block"
    },
    "condition": {
      "urlFilter": "cookie.domain.example^",
      "resourceTypes": [
        "main_frame",
        "sub_frame",
        "script",
        "image",
        "xmlhttprequest"
      ]
    }
  },
```

## How to run

First run ```python data_fetcher.py``` which will fetch up to date adware-malware dns domains from [StevenBlack/hosts](https://raw.githubusercontent.com/StevenBlack/hosts/refs/heads/master/hosts) and place them in the [ad-domins.txt](/ad-domains.txt) file, after which run the ```python rules_creator.py``` creating the static json rules for the extension which are used by [manifest.json](/extension/manifest.json)

## License

This project is under the Apache 2.0 license. You can check the details of the license [here](/LICENSE) 

StevenBlack/hosts repository where the adware-malware dns domains are collected is under the MIT license with the following [link](https://github.com/StevenBlack/hosts?tab=MIT-1-ov-file)