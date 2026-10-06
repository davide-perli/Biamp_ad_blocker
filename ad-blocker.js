let adDomains = [];

fetch(chrome.runtime.getURL('ad-domains.txt'))
  .then(response => response.text())
  .then(text => {
    adDomains = text.split('\n').map(domain => domain.trim()).filter(Boolean);
  });

function isAdDomain(url) {
  try {
    const hostname = new URL(url).hostname;
    return adDomains.some(domain =>
      hostname === domain || hostname.endsWith('.' + domain)
    );
  } catch {
    return false;
  }
}

chrome.webRequest.onBeforeRequest.addListener(
  function(details) {
    if (isAdDomain(details.url)) {
      // console.log('Blocked domain:', new URL(details.url).hostname);
      return { cancel: true };
    }
    return { cancel: false };
  },
  { urls: ["<all_urls>"] },
  ["blocking"]
);