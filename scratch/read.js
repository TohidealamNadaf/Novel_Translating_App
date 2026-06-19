setTimeout(function() {
    var images = $('.content-pics img');
    if (images.length > 0) {
        images.each(function() {
            var oldImg = $(this).attr('src');
            var newImg = 'https://8book.com' + oldImg;
            $(this).attr('src', newImg);
            $(this).css('width', '100%');
            $(this).parent('li').css('list-style', 'none');
        });
    }
}, 1500);

 // å®ä¹ææä¸»é¢éé¡¹
  // æ³¨æï¼bg_mode0 ä¸ºå¤é´æ¨¡å¼ï¼å¶ä½ä¸ºæ¥é´æ¨¡å¼çä¸åèæ¯é¢è²
  var themes = [
    { color: "#ffffff", title: "ç½é²ç½", mode: "bg_mode1" },
    { color: "#cddfcd", title: "å¯¶ç³ç¶ ", mode: "bg_mode2" },
    { color: "#cfdde1", title: "æµ·ä¹è", mode: "bg_mode3" },
    { color: "#ede7da", title: "å¯è²´é»", mode: "bg_mode4" },
    { color: "#d0d0d0", title: "å·é·ç°", mode: "bg_mode5" }
  ];

  // ç¨äºç»ä¸åºç¨ä¸»é¢çå½æ°
  function applyTheme(theme) {
    // ä¿å­ä¸»é¢å°localStorage
    localStorage.setItem('theme', theme);
    // è®¾ç½®é¡µé¢ä¸»ä½classï¼ä¾¿äºCSSæ©å±ï¼å¦ææåºäºclassçæ ·å¼ï¼å¯å¨è¿éä½¿ç¨ï¼
    document.body.className = theme;
    
    if (theme === 'bg_mode0') {
      // å¤é´æ¨¡å¼ï¼æ¯å¦é»åºç½å­ï¼è¿éå¯æ ¹æ®å®ééæ±è°æ´ï¼
      $("body").css({"background": "#000000", "color": "#ffffff"});
      // ä¿®æ¹æ¥å¤æé®çæ¾ç¤ºåå®¹
      document.querySelectorAll('.modecbtn1, .modecbtn2').forEach(button => {
        button.innerHTML = '<img class="night-on" src="https://8book.com/images/night-mode.svg" alt="éç">éç';
      });
    } else {
      // æ¥é´æ¨¡å¼ï¼æ ¹æ®ä¸åä¸»é¢è®¾ç½®å¯¹åºçèæ¯è²åæå­é¢è²
      // å®ä¹ä¸ä¸ªæ å°å³ç³»
      var mapping = {
        bg_mode1: { bg: "#ffffff", color: "#111111" },
        bg_mode2: { bg: "#cddfcd", color: "#111111" },
        bg_mode3: { bg: "#cfdde1", color: "#111111" },
        bg_mode4: { bg: "#ede7da", color: "#111111" },
        bg_mode5: { bg: "#d0d0d0", color: "#111111" }
      };
      var style = mapping[theme] || mapping['bg_mode1'];
      $("body").css({"background": style.bg, "color": style.color});
      document.querySelectorAll('.modecbtn1, .modecbtn2').forEach(button => {
        button.innerHTML = '<img class="day-on" src="https://8book.com/images/day-mode.svg" alt="éç">éç';
      });
    }
  }

  // æ¥å¤æ¨¡å¼æé®1ï¼ä¸æé®2ä½ç¨ç±»ä¼¼ï¼
  function modecbtn1() {
    var currentTheme = localStorage.getItem('theme');
    // å¦æå½åä¸ºå¤é´æ¨¡å¼ååæ¢å°é»è®¤æ¥é´æ¨¡å¼ï¼bg_mode1ï¼ï¼å¦ååæ¢å°å¤é´æ¨¡å¼
    if (currentTheme === 'bg_mode0') {
      applyTheme('bg_mode1');
    } else {
      applyTheme('bg_mode0');
    }
  }

  // é¡µé¢å è½½æ¶æ¢å¤ä¸æ¬¡è®¾ç½®çä¸»é¢
  document.addEventListener('DOMContentLoaded', function() {
    var savedTheme = localStorage.getItem('theme') || 'bg_mode1';
    applyTheme(savedTheme);

    // å¨æçæèæ¯é¢è²éé¡¹ï¼ä»çææ¥é´æ¨¡å¼çéé¡¹ï¼ä¸åå«å¤é´æ¨¡å¼ï¼
    var $bgOptions = $(".bg-options");
    $.each(themes, function(index, theme) {
      var $a = $("<a>", {
        class: "cb",
        title: theme.title,
        css: { backgroundColor: theme.color },
        click: function() {
          // ç¹å»æ¶åºç¨å¯¹åºçä¸»é¢
          applyTheme(theme.mode);
          // éèèæ¯éé¡¹åºå
          $bgOptions.slideUp(300);
        }
      });
      $bgOptions.append($a);
    });

    // ç»å®æ§å¶æé®ç¹å»äºä»¶ï¼ç¹å»è°è²å¾æ æ¶å¨ç»å±å¼/éèèæ¯éé¡¹åºå
    $(".read-ctrl .ft-item:first-child img").on("click", function() {
      $bgOptions.slideToggle(300);
    });
  });


  $(document).ready(function(){
      $('#SubmitErrorBtn').click(function(){
          var lastSubmitTime = localStorage.getItem('lastSubmitTime');
          if (lastSubmitTime && (Date.now() - parseInt(lastSubmitTime)) < (5 * 60 * 1000)) {
              alert("æ¨å·²åå ±é¯èª¤ï¼è«å¿éè¤åå ±ã");
              return false;
          } else {
              var submitErrorType = $('#submitErrorType').val();
              if (!submitErrorType) {
                  alert("è«é¸æé¯èª¤é¡å¥");
                  return false;
              }
              
              var submitErrorMessage = $('#submitErrorMessage').val();
              if (!submitErrorMessage) {
                  alert("è«æä¾å·é«é¯èª¤");
                  return false;
              } else {
                  $.get("https://www.8book.com/member/msgautoreports.aspx?submit=1&r=0&title=é é¢é¯èª¤å ±å&content="+"<a href='"+document.location.href+"' target='_blank'>"+document.location.href+"</a><br>"+submitErrorType+"<br>"+encodeURIComponent(submitErrorMessage), { submitErrorType: submitErrorType }, function(data){
      //  After report's operation
      alert('æè¬æ¨çåå ±ï¼æåå°å¨æ¥å¯¦åä¿®æ­£ã');
	$('#submitErrorModal').modal('hide')
	                }
					);
                  $.get("https://api.telegram.org/bot1942675180:AAEarBsTl_p7UZPBFlng05G6vKm_t0tMUlk/sendMessage?chat_id=687452790&text="+"é é¢é¯èª¤å ±å%0A"+submitErrorType+"%0A"+document.location.href);
      localStorage.setItem('lastSubmitTime', Date.now().toString());
      return false; 
              }
          }
      });
  });



var allowInput=0;
var downloading=0;
var y=46;
var ie = (navigator.userAgent.toLowerCase().indexOf("chrome")<0 && navigator.userAgent.toLowerCase().indexOf("safari")<0) ;
var safari = (navigator.userAgent.toLowerCase().indexOf("safari")>=0 && navigator.userAgent.toLowerCase().indexOf("chrome")<0);
function ten(s){if(s<10) return "0"+s;else return s; }
function getdate(s){if(s==null) s="-";var d=new Date();return d.getFullYear()+s+ten((d.getMonth()+1))+s+ten(d.getDate());}
function gettime(s){if(s==null) s=":";var d=new Date();return ten(d.getHours())+s+ten(d.getMinutes())+s+ten(d.getSeconds());}
function meta(str){var str=$("meta[name='"+str+"']").attr("content");if(typeof(str)=="undefined") return "";else return str;}


	//setTimeout(function(){$(".content").show();},800);
	//var font=setFont();

	$("#bt_back,#bt_up,#bt_back_menu").on("click",function(e){
		if(document.referrer.indexOf("/book")>0 ||document.referrer.indexOf("/novelbook")>0) history.back();
		else window.location.replace("/novelbooks/"+meta("itemid"));
		});


//if(screen.width<1024) $(".navbar").hide();
$("body").on("click",function(){if(event.target.nodeName!="A" && event.target.nodeName!="LI" && event.target.nodeName!="BUTTON" && event.target.nodeName!="SPAN") {
	if($(".adsbygoogle-noablate[data-anchor-shown='true']").length>0)
	{
		var ad=$(".adsbygoogle-noablate[data-anchor-shown='true']");
		var t=parseInt(ad.css("top").replace("px",""));
		var h=parseInt(ad.css("height").replace("px",""));
		var s=ad.attr("data-anchor-status");
		if(s=="dismissed") h=5;
		console.log($(".adsbygoogle-noablate[data-anchor-shown='true']").css("display")+" s:"+s +" t:"+t+" h:"+h);
		if(t<=0 && h>0)
		{
			$(".navbar").css("top",h);
		}
	}
	else {$(".navbar").css("top",0);}
	
	
if(screen.width<1024) {
	if($(".contentbts").is(":hidden")) {$(".contentbts").show(300);$(".navbar").show(300);}else {$(".contentbts").hide(300);$(".navbar").hide(300);}}
	else $(".contentbts").fadeToggle(300);$("#backgroundset").hide();
	


	}
});

// å®ä¹å­ä½å¤§å°åå¯¹åºçè¡é«æ°æ®ï¼ä»å°å°å¤§ï¼
const fonts = [
    { size: "1rem",  lineHeight: "1.6" },
    { size: "1.2rem", lineHeight: "1.8" },
    { size: "1.4rem", lineHeight: "1.8" },
    { size: "1.6rem", lineHeight: "2" },
    { size: "2rem",   lineHeight: "2" }
];

// æ ¹æ®å­ä½å¤§å°è®¾ç½®æ ·å¼ï¼å¢å åºå®ç letter-spacing
function setFont(f) {
    if (!f || f === "NaN" || f === "") {
        f = "1.2rem";  // é»è®¤æ¹ä¸º 1.2rem
    }
    // æ¥æ¾å¯¹åºçæ°æ®ï¼è¥æªæ¾å°åé»è®¤å 1.2remï¼ç´¢å¼ä¸º1ï¼
    const fontObj = fonts.find(item => item.size === f) || fonts[1];
    $(".text").css({
        "font-size": fontObj.size,
        "line-height": fontObj.lineHeight,
        "letter-spacing": "1px"
    });
    localStorage.setItem("font", fontObj.size);
    return fontObj.size;
}

// å¦æå·²ç»å¨åé¢è°ç¨äº setFont()ï¼åä¸éè¦åæ¬¡åå§åå­ä½
var font = setFont(localStorage.getItem("font"));

// è·åå½åå­ä½å¨ fonts æ°ç»ä¸­çç´¢å¼ï¼é»è®¤ç´¢å¼ä¸º1ï¼å¯¹åº 1.2remï¼
function getCurrentFontIndex() {
    const current = localStorage.getItem("font");
    const idx = fonts.findIndex(item => item.size === current);
    return idx !== -1 ? idx : 1;
}

// æ ¹æ® delta æ¹åå­ä½å¤§å°ï¼delta ä¸º -1 æ +1ï¼
function changeFont(delta) {
    let index = getCurrentFontIndex();
    index = Math.min(Math.max(index + delta, 0), fonts.length - 1);
    setFont(fonts[index].size);
}

// ç»å®æé®ç¹å»äºä»¶
$(".font-decrease").on("click", () => changeFont(-1));  // å­ä½åå°
$(".font-increase").on("click", () => changeFont(1));     // å­ä½å¢å¤§

function saveitem(type,str)
{
	if(str==null)
	{
		str={"id":meta("id"),"url":meta("url"),"pic":meta("pic"),"name":meta("name"),"count":meta("count"),"author":meta("author"),"update":meta("update"),"eps":"","date":getdate()+" "+gettime()}
	}
	var newitem=eval(str);
	
	
	var s=localStorage.getItem(type);
	
	if(s==null || s=="")
	{
		
		localStorage.setItem(type,"items:["+JSON.stringify(newitem)+"]");
		
	}
	else
	{
		
		var max=1000;if(type=="history") max=100;
		var items=eval(s);var f=0;
		for(var i=0;i<items.length&&i<max;i++) if(items[i].id==newitem.id) {
			newitem.eps=items[i].eps;
			newitem.url=items[i].url;
			if(type!="download") items.splice(i,1);f=1;
			}
		newitem.date=getdate();
		if(f==0 || type!="download") items.unshift(newitem);
		
		localStorage.setItem(type,JSON.stringify(items));
		

	}
}
function delitem(type,id,bd)
{
	//var s=localStorage.getItem(type);
	var s=localStorage.getItem(type);
	if(s!=null || s!="")
	{
		var items=eval(s);
		for(var i=0;i<items.length;i++) if(items[i].id==id) items.splice(i,1);
		
		localStorage.setItem(type,JSON.stringify(items));

	}
	if(bd!=null)
	{
		if($("#li"+id).length>0) $("#li"+id).remove();
		if(type=="bookmark" && islogin()) $.get("/user/addbookmark.aspx?del=1&d=1&id="+id);
	}		
	//console.log("h:"+localStorage.getItem("h"));
}
function ae(type,id,ep,url)
{

	//var s=localStorage.getItem(type);
	var s=localStorage.getItem(type);
	
	if(s!=null && s!="")
	{
		var items=eval(s);
		for(var i=0;i<items.length;i++) if(items[i].id==id)
		{
			//if(items[i].eps=="") 
			{
				items[i].eps=ep;
				items[i].url=url;
				items[i].date=getdate()+" "+gettime();
			}
		}
		
		localStorage.setItem(type,JSON.stringify(items));
		
	}
	else
	{
		saveitem(type,{"id":id,"url":url,"eps":ep});
	}
	var uu=document.location.href.substring(9);uu=uu.substring(uu.indexOf('/'));
	
	setTimeout(function(){if(document.getElementById('ifr')) document.getElementById('ifr').contentWindow.postMessage({"id":id,"url":uu,"eps":ep}, "*");},500);
	

}
function hasitem(type,id)
{
	//var s=localStorage.getItem(type);
	var s=localStorage.getItem(type);
	if(s!=null && s!="")
	{
		var items=eval(s);
		for(var i=0;i<items.length;i++) if(items[i].id==id)
		{
			return true;
		}
		
	}
	return false;
}
function getitem(type,id)
{
	//var s=localStorage.getItem(type);
	var s=localStorage.getItem(type);
	var str="";
	if(s!=null && s!="")
	{
		var items=eval(s);
		for(var i=0;i<items.length;i++) if(items[i].id==id)
		{
			return items[i];
		}
	}
	return null;
}
function showitem(type)
{
	//var s=localStorage.getItem(type);var str="";
	var s=localStorage.getItem(type);
	if(s!=null && s!="")
	{
		var items=eval(s);
		for(var i=0;i<items.length;i++)
		{
			str+="<li id='li"+items[i].id+"'><del onclick=\"delitem('"+type+"',"+items[i].id+",1);\"></del>";
			str+="<a href='"+items[i].url+"' data-ajax='false' data-url='"+items[i].id+"'>"; 
			str+="<img src='"+items[i].pic+"' /><h3>"+items[i].name+"<i>"+items[i].count+"</i></h3></a>";
			str+="<b>&#20316;&#32773;&#65306;"+items[i].author+"</b>";
			if(type=="history" || type=="bookmark")
			{
				
				if(items[i].date && items[i].date!="" )str+="<b>&#35370;&#21839;&#65306;"+items[i].date+"</b>";
				if(items[i].eps && items[i].eps!="" )str+="<b>&#30475;&#21040;&#65306;<a href='"+items[i].url+"'>"+items[i].eps+"</a></b>";
			}
			else if(type=="bookmark")
			{
				
				str+="<b>&#20316;&#32773;&#65306;"+items[i].author+"</b>";
				if(items[i].date && items[i].date!="" )str+="<b>&#26356;&#26032;&#65306;"+items[i].date+"</b>";
			}

			str+="</li>";
		}
		document.getElementById(type).innerHTML=str;
	}
}

function syncbookmark(show)
{
	
	//localStorage.setItem("bookmark","");
	localStorage.setItem("bookmarkdate","");
	if(islogin() && localStorage.getItem("bookmarkdate")!=getdate())
	{
		$.get("/user/bookmarkjs.aspx",function(data,status){
			if(status=="success")
			{
				var newitems=eval(data);
				var s=localStorage.getItem("bookmark");
				var items=eval(s);var f=0;
				if(s==null || s==""){ items=newitems;}
				else
				{
					for(var i=0;i<newitems.length;i++){
						var item=newitems[i];
						for(var j=0;j<items.length;j++) if(items[j].id==item.id) {f=1;}
						if(f==0) items.push(item);
					}
				}
				localStorage.setItem("bookmark",JSON.stringify(items));
			}
			if(show)showitem('bookmark');
			localStorage.setItem("bookmarkdate",getdate());
		});
	}
	else if(show)showitem('bookmark');
}
	
function getcookie(Name) {var search = Name + "=";if (document.cookie.length > 0) { offset = document.cookie.indexOf(search);if (offset != -1) {offset += search.length;end = document.cookie.indexOf(";", offset);if (end == -1)end = document.cookie.length;return unescape(document.cookie.substring(offset, end))
}else return "";}else return "";}
function setcookie(n, v){
var expiredays=365;var expire_date = new Date();expire_date.setDate(expire_date.getDate() + expiredays );document.cookie = n + "=" + escape( v ) + "; expires=" + expire_date.toGMTString() + "; path=/ ; samesite=none;secure;";
}
var uid=getcookie("8CKID");
var uno=getcookie("8CKNO");
function islogin(){uid=getcookie("8CKID");uno=getcookie("8CKNO");if(uid!=null && uid!="" && uid.indexOf("WG#")>0) return true;else return false;}
function isadm(){var a=getcookie("8CKAM");if(a!=null && a!="" && a.indexOf("3Gk")>0) return true;else return false;}

function request(queryStringName)
{var returnValue="";
var URLString=new String(document.location);
var serachLocation=-1;
var queryStringLength=queryStringName.length;
do{serachLocation=URLString.indexOf(queryStringName+"\=");
if (serachLocation!=-1){if ((URLString.charAt(serachLocation-1)=='?') || (URLString.charAt(serachLocation-1)=='&'))
{URLString=URLString.substr(serachLocation);break;}URLString=URLString.substr(serachLocation+queryStringLength+1);}}
while (serachLocation!=-1)
if (serachLocation!=-1)
{var seperatorLocation=URLString.indexOf("&");
if (seperatorLocation==-1){returnValue=URLString.substr(queryStringLength+1);}
else{returnValue=URLString.substring(queryStringLength+1,seperatorLocation);} }
return returnValue;}

function reurl(keyname,keyvalue){var u=document.location.href;if(u.indexOf('#')==u.length-1) u=u.substring(0,u.length-1);if(u.indexOf('?')>0){return u.substring(0,u.indexOf('?'))+'?'+keyname+'='+keyvalue+('&'+u.substring(u.indexOf('?')+1)).replace(eval('/&'+keyname+'=[^&]*/gi'),''); }else return u+'?'+keyname+'='+keyvalue;} 

function getx(obj) {var curleft = 0;if (obj.offsetParent){while (obj.offsetParent){curleft += obj.offsetLeft;obj = obj.offsetParent;}}else if (obj.x) {curleft += obj.x;}return curleft;}
function gety(obj) {var curtop = 0;if (obj.offsetParent){while (obj.offsetParent){curtop += obj.offsetTop;obj = obj.offsetParent;}}else if (obj.y) {curtop += obj.y;}return curtop;}

function rgb(str){hexcode="#";str=str.replace("rgb","").replace("(","").replace(")","").replace(/\s/g,"");
for(x=0;x<3;x++){var n=str.split(',')[x];if(n=="") n=0;var c="0123456789ABCDEF", b="", a=n%16;b=c.substr(a,1);a=(n-a)/16;hexcode+=c.substr(a,1)+b};return hexcode;}



function add1(e){toast(e);}

function toast(e,str){if(str==null) str="+1";anim="a"+parseInt(Math.random()*10000); var v=e.innerHTML;if(v.lastIndexOf("</font>")>0) v=v.substring(v.lastIndexOf("</font>")+7);e.style.color="#ff0000";e.style.textShadow="#fff 0px 0px 3px";var html="<font id='"+anim+"' style='font-size:15px;font-family:arial black;position:absolute;color:#ff0000;text-shadow:#fff 0px 0px 3px;'><nobr>"+str+"</nobr></font>"+v;e.innerHTML=html;$("#"+anim).animate({top:"-20px"},function(){$(this).remove();});
}

function rt(t){return t;}


function rtp(t, p, l, x) {
  var tt = t.split(/(?:<br\s*\/?>)+/gi)
    .map(item => item.replace(/^(?:[\sã]|&nbsp;)+|(?:[\sã]|&nbsp;)+$/g, ''))
    .filter(item => item.trim().length > 0 && !item.trim().startsWith('<!--'));
  if (p < 1) p = 1;
  var tp = Math.floor(tt.length / l) + (tt.length % l > 10 ? 1 : 0);
  if (p > tp) p = tp;
  var tx = "<!--|" + tp + "|-->";
  for (var i = (p - 1) * l; i < tt.length; i++) {
    if (typeof(tt[i]) !== "undefined")
      tx += "<span class='read_spans'>" + tt[i] + "</span><br>";
    if (i >= p * l && p < tp) break;
  }
  return "<p>" + tx + "</p>";
}

setTimeout(function(){if($(".empty").text().length>5) location.href="https://www.8book.com/novelbooks/"+meta("itemid");},1500);



$(document).ready(function () {
    var cid = meta("catid");
    var nurl = '';

    // redirect by cid
    if ((cid == 3 || cid == 4 || cid == 9) && window.location.href.indexOf('8book.com') > 0) {
        nurl = 'https://finance.binaccount.com';
    } else if ((cid == 1 || cid == 2 || cid == 5 || cid == 6 || cid == 8 || cid == 10 || cid == 11 || cid == 14) && window.location.href.indexOf('8book.com') > 0) {
        nurl = 'https://sport.thepaperbooks.com';
    }

    var currentUrl = window.location.href;

    if (nurl) {
        var turl = currentUrl.replace(window.location.origin, nurl);
        window.location.href = turl;
        return;  
    }

    if (currentUrl.indexOf('book.thepaperbooks.com') > -1 && currentUrl.indexOf('sport.thepaperbooks.com') === -1) {
        var newUrl = currentUrl.replace('book.thepaperbooks.com', 'sport.thepaperbooks.com');
        window.location.href = newUrl;
        return;
    }

    if (currentUrl.indexOf('articles.binaccount.com') > -1 && currentUrl.indexOf('finance.binaccount.com') === -1) {
        var newUrl = currentUrl.replace('articles.binaccount.com', 'finance.binaccount.com');
        window.location.href = newUrl;
        return;
    }
});
