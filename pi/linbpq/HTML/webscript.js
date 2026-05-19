// M6VPN-7 - Developed by M6VPN (M6VPN@tuta.com)
// M6VPN-7/pi/linbpq/HTML/webscript.js
// Version 2 17/10/2018
var Main
var fromleft;

function addM6VPNScript(src)
{
	var scripts = document.getElementsByTagName('script');
	var script;
	var i;

	for (i = 0; i < scripts.length; i += 1) {
		if (scripts[i].getAttribute('src') === src) {return;}
	}

	script = document.createElement('script');
	script.src = src;
	document.head.appendChild(script);
}

function addM6VPNStyle(href)
{
	var links = document.getElementsByTagName('link');
	var link;
	var i;

	for (i = 0; i < links.length; i += 1) {
		if (links[i].getAttribute('href') === href) {return;}
	}

	link = document.createElement('link');
	link.rel = 'stylesheet';
	link.href = href;
	document.head.appendChild(link);
}

function loadM6VPNAssets()
{
	if (!document.head) {return;}

	addM6VPNStyle('/m6vpn.css');
	addM6VPNScript('/m6vpn-ui.js');
}

loadM6VPNAssets();

function initialize(mainoffset)
{
	var w=window,d=document,e=d.documentElement,g=d.getElementsByTagName('body')[0];
	x=w.innerWidth||e.clientWidth||g.clientWidth;
	y=w.innerHeight||e.clientHeight||g.clientHeight;
	Main = document.getElementById("main");
	if (!Main) {return;}
	w = x;
	if (w > 920) {w = 920;}
	fromleft = (x / 2) - (x - 150)/2;
	if (fromleft < 0) {fromleft = 0;}
	Main.style.left = fromleft + "px";
	Main.style.width = x - 150 + "px";
	Main.style.height = y - mainoffset + "px";
}
function newmsg(Key)
{
var param = "toolbar=yes,location=yes,directories=yes,status=yes,menubar=yes,scrollbars=yes,resizable=yes,titlebar=yes,toobar=yes";
window.open("/WebMail/NewMsg?" + Key,"_self",param);
}
function Reply(Num, Key)
{
var param = "toolbar=yes,location=yes,directories=yes,status=yes,menubar=yes,scrollbars=yes,resizable=yes,titlebar=yes,toobar=yes";
window.open("/WebMail/Reply/" + Num + "?" + Key,"_self",param);
}
