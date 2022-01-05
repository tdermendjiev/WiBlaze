// 'use strict';
console.log("BACKGORUND CALLED")
const restrictions = {
  'adweek.com': /^((?!\.adweek\.com\/(.+\/)?(amp|agencyspy|tvnewser|tvspy)\/).)*$/,
  'barrons.com': /.+barrons\.com\/(amp\/)?article(s)?\/.+/,
  'economist.com': /.+economist\.com\/.+\/\d{1,4}\/\d{1,2}\/\d{2}\/.+/,
  'seekingalpha.com': /.+seekingalpha\.com\/article\/.+/,
  'techinasia.com': /\.techinasia\.com\/.+/,
  'ft.com': /.+\.ft.com\/content\//
};

// Don't remove cookies before page load
const allowCookies = [
  'ad.nl',
  'asia.nikkei.com',
  'bd.nl',
  'bndestem.nl',
  'brisbanetimes.com.au',
  'canberratimes.com.au',
  'cen.acs.org',
  'chicagobusiness.com',
  'demorgen.be',
  'denverpost.com',
  'destentor.nl',
  'ed.nl',
  'examiner.com.au',
  'gelocal.it',
  'gelderlander.nl',
  'grubstreet.com',
  'harpers.org',
  'hbr.org',
  'humo.be',
  'lesechos.fr',
  'lrb.co.uk',
  'medium.com',
  'mercurynews.com',
  'newstatesman.com',
  'nrc.nl',
  'nymag.com',
  'ocregister.com',
  'parool.nl',
  'pzc.nl',
  'qz.com',
  'scientificamerican.com',
  'seattletimes.com',
  'seekingalpha.com',
  'sofrep.com',
  'spectator.co.uk',
  'speld.nl',
  'tubantia.nl',
  'techinasia.com',
  'telegraaf.nl',
  'the-american-interest.com',
  'theadvocate.com.au',
  'theage.com.au',
  'theatlantic.com',
  'theaustralian.com.au',
  'thecut.com',
  'thediplomat.com',
  'themercury.com.au',
  'towardsdatascience.com',
  'trouw.nl',
  'vn.nl',
  'volkskrant.nl',
  'vulture.com',
  'washingtonpost.com',
  'nzz.ch',
  'handelsblatt.com',
  'thehindu.com',
  'financialpost.com',
  'haaretz.co.il',
  'haaretz.com',
  'themarker.com',
  'sueddeutsche.de',
  'gelocal.it',
  'elmundo.es',
  'time.com',
  'zeit.de'
];

// Removes cookies after page load
const removeCookies = [
  'ad.nl',
  'asia.nikkei.com',
  'bd.nl',
  'bloombergquint.com',
  'bndestem.nl',
  'brisbanetimes.com.au',
  'canberratimes.com.au',
  'cen.acs.org',
  'chicagobusiness.com',
  'demorgen.be',
  'denverpost.com',
  'destentor.nl',
  'ed.nl',
  'examiner.com.au',
  'gelderlander.nl',
  'globes.co.il',
  'grubstreet.com',
  'harpers.org',
  'hbr.org',
  'humo.be',
  'lesechos.fr',
  'mercurynews.com',
  'newstatesman.com',
  'nrc.nl',
  'nymag.com',
  'ocregister.com',
  'pzc.nl',
  'qz.com',
  'scientificamerican.com',
  'seattletimes.com',
  'sofrep.com',
  'spectator.co.uk',
  'speld.nl',
  'telegraaf.nl',
  'theadvocate.com.au',
  'theage.com.au',
  'theatlantic.com',
  'thecut.com',
  'thediplomat.com',
  'towardsdatascience.com',
  'tubantia.nl',
  'vn.nl',
  'vulture.com',
  'wsj.com'
];

// Contains remove cookie sites above plus any custom sites
let _removeCookies = removeCookies;

// select specific cookie(s) to hold from removeCookies domains
const removeCookiesSelectHold = {
  'qz.com': ['gdpr'],
  'wsj.com': ['wsjregion'],
  'seattletimes.com': ['st_newsletter_splash_seen']
};

// select only specific cookie(s) to drop from removeCookies domains
const removeCookiesSelectDrop = {
  'ad.nl': ['temptationTrackingId'],
  'ambito.com': ['TDNotesRead'],
  'bd.nl': ['temptationTrackingId'],
  'bndestem.nl': ['temptationTrackingId'],
  'demorgen.be': ['TID_ID'],
  'destentor.nl': ['temptationTrackingId'],
  'ed.nl': ['temptationTrackingId'],
  'fd.nl': ['socialread'],
  'gelderlander.nl': ['temptationTrackingId'],
  'humo.be': ['TID_ID'],
  'nrc.nl': ['counter'],
  'pzc.nl': ['temptationTrackingId'],
  'tubantia.nl': ['temptationTrackingId'],
  'speld.nl': ['speld-paywall']
};

// Override User-Agent with Googlebot
const useGoogleBotSites = [
  'adelaidenow.com.au',
  'barrons.com',
  'couriermail.com.au',
  'dailytelegraph.com.au',
  'fd.nl',
  'genomeweb.com',
  'heraldsun.com.au',
  'lavoixdunord.fr',
  'ntnews.com.au',
  'quora.com',
  'seekingalpha.com',
  'telegraph.co.uk',
  'theaustralian.com.au',
  'themercury.com.au',
  'thenational.scot',
  'thetimes.co.uk',
  'wsj.com',
  'kansascity.com',
  'republic.ru',
  'nzz.ch',
  'handelsblatt.com',
  'df.cl',
  'ft.com',
  'wired.com',
  'zeit.de'
];

// Override User-Agent with Bingbot
const useBingBot = [
  'haaretz.co.il',
  'haaretz.com',
  'themarker.com'
];

// Contains google bot sites above plus any custom sites
let _useGoogleBotSites = useGoogleBotSites;

var setDefaultOptions = function () {
}
