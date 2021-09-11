/* simple parser */

/* lexical grammar */
%lex

word         [a-zA-Z]+
number       [0-9]+
space			[\t \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]
other        [^a-zA-Z0-9 \n]+ 

%%

(mixin|include)        return 'KEYWORD';
{word}       return 'WORD';
{number}     return 'NUMBER';
'('             return 'LPAREN';
')'             return 'RPAREN';
{other}      return 'OTHER';
{space}      return 'SPACE';
<<EOF>>      return 'ENDOFFILE';
\n           return 'NEWLINE'; // ignore newlines

/lex

%% 


/* language grammar */

start
  : ENDOFFILE
  { console.log("empty string"); $$ = [] }
  | list ENDOFFILE
  { console.log("list ENDOFFILE", $1); $list = [] }
  ;

list
  : list token
  { $list.push($token); $$ = $list; }
  | line
  { $list.push($token); $$ = $list; }
  | token
  { $$ = [$token]; }
  ;

line
  : 
  : LPAREN token RPAREN
  ;

token
  : WORD
  { console.log("WORD=%s", $$); }
  | NUMBER 
  { console.log("NUMBER=%s", $$); $$ = parseInt($$) }
  | OTHER
  | SPACE
  { $$ = 'SPACE' }
  | KEYWORD
  | NEWLINE
  { $$ = 'NEWLINE' }
  ;

%% 

// feature of the GH fork: specify your own main.
//
// compile with
// 
//      jison -o test.js --main path/to/simple.jison
//
// then run
//
//      node ./test.js
//
// to see the output.

var assert = require("assert");

parser.main = function () {

  function test(input, expected) {
    console.log(`\nTesting '${input}'...`)
    var actual = parser.parse(input)
    console.log(input + ' ==> ', JSON.stringify(actual))
    assert.deepEqual(actual, expected)
  }

  test(`
extends ../../../../templates/blogpost

append variables
  - var title = "Moving off Wordpress and on to Netlify"
  - var posted = '2021-09-08'

block morehead
  script(src='https://code.jquery.com/jquery-3.6.0.min.js' integrity='sha256-/xUj+3OJU5yExlq6GSYGSHk7tPXikynS7ogEvDej/m4=' crossorigin='anonymous')
  script(src="/node_modules/jquerykeyframes/dist/jquery.keyframes.min.js")

  style.
    #bandwagonLink img {
      vertical-align: top;
    }
    .popupGator {
      background-image: url('/src/img/hostgator_icon.png');
      display: inline-block;
      background-repeat: no-repeat;
      background-position-x: 25px;
      background-position-y: 25px;
      text-decoration: underline dashed;
      transition-property: background-position-y;
      transition-duration: 2s;
    }
    .popupGator:hover {
        background-position-y: 0px;
    }

    li {
      margin-left: 25px;
    }

    #dns-before td, #dns-after td {
      border: 1px darkgray solid;
    }
    #dns-before tr, #dns-after tr {
      border: 1px darkgray solid;
    }
    #dns-before th, #dns-after th {
      font-weight: bold;
      text-rendering: geometricprecision;
      border: 1px darkgray solid;
    }
    #dns-before td, #dns-after td,
    #dns-before th, #dns-after th {
      padding: 5px 8px;
    }
    #dns-arrows {
      top: 50%;
      position: relative;
      transform: translateY(-50%);
    }
    img.icon {
      margin: 0 5px;
      height: 1.2em;
    }
    @keyframes myFadeOut {
      from {
        opacity: 1;
      }
      to {
        opacity: 0;
      }
    }

block body

  .container.post#post-20210905
    .posted= posted
    .content
      h2 Preface
      p This post has been a long time coming. I started writing this Thursday, August 26. It's now September.
      h2#intro Why?
      p I started down the path of converting my Wordpress site to a static site because I started getting (or at least started getting notified of) &quot;hackers&quot; scanning my site for Wordpress vulnerabilities. 
        | I installed a plugin called 
        a(href="https://www.wordfence.com/" title="Wordfence Homepage") Wordfence
        | , which I have to say, is an awesome app for being free. It could block IPs that were hitting the site and you could configure it with how many hits before blocking or if they hit a specific URL known for a vulnerability. 
        | I don't know if there was an upgrade but I started seeing my site getting hit and I wanted to jump on the static site generator bandwagon before it was, you know, gone.
      a#bandwagonLink(title='Influx, CC BY-SA 4.0 &lt;https://creativecommons.org/licenses/by-sa/4.0&gt;, via Wikimedia Commons' href='https://commons.wikimedia.org/wiki/File:Bandwagon.jpg')
        img(alt='Bandwagon' src='/src/img/bandwagon.png')

      h2 Requirements

        #email
        h3 Email aliases
        p I use my email aliases a lot. I have almost 500 aliases. By creating email aliases I can further increase my personal security by using a different email <em>and</em> password on websites. I can see when a website a) sold my email or b) was compromised and discard any emails addressed to that address. 

      h2 Searching

      #email_hosting
      h3 Email Hosting
      p I've been using 
        span.popupGator Hostgator 
        |  for 10 years now and have been pretty happy with it. I was only planning on switching if I found another way to host that was cheaper 
        span.underline and
        |  I still had unlimited email aliases. 

      p I looked at 
        a(href="https://www.godaddy.com/email/professional-business-email") GoDaddy's email solution
        |  and 
        a(href="https://workspace.google.com/") Google's Workspace (formally G Suite)
        |  but neither had unlimited aliases. So I decided to stick with HostGator for email. 

      #website_hosting
      h3 Website Hosting
      h4 AWS 
      p When I started looking at alternate hosting solutions. I looked at AWS first but I <em>think</em> you have to have a Route 53 route set up if you want to use your own domain name. And 
        a(href="https://aws.amazon.com/route53/pricing/" title="$50/month") the cost
        |  of that was more than what I am paying now. 


      #netlify
      h4 Netlify 
      p I've "kicked the tires" before and they wow'd me with 
        a(href="https://thanosjs.org/") ThanosJS
        |  . Ok, not really with the the ThanosJS, but with the tool used to deploy it: 
        a(href="https://app.netlify.com/drop") Netlify Drop
        |  .

      p When I tested the deploy this time it went smoothly so, that's where I'm at now.

      h2 Steps
      h3 Separating the email and site servers
      p I first had to split my current site that served as my email server and my webserver. I did some research into domain name records.

      ol DNS resources
        li: a(href="https://www.cloudflare.com/learning/dns/dns-records/" title="DNS records definitions") DNS records definitions
        li
          a(href="https://www.hostgator.com/help/article/how-to-route-email-to-your-server-independently" title="How to Route Email to Your Server Independently") HostGator article
          |  which has been deprecated since I last saw it and took the time to comment and report that it was outdated. 🤔 
        li
          a(href="https://hostadvice.com/how-to/how-to-configure-email-on-a-different-host-from-the-website/" title="How to Configure Email on a Different Host from the Website") How to Configure Email on a Different Host from the Website
          |  It wasn't up-to-date either, but provided clues to get me there
        li
          a(href="https://docs.netlify.com/domains-https/custom-domains/configure-external-dns/" title="Netlify's documentation on configuring an external DNS for a custom domain") Configure external DNS for a custom domain

      h4 DNS Steps
      h5 Mail Server Settings
      p I basically had to set up an existing subdomain to instead point to an IP address and not to my root domain. What was not documented was what to do if that subdomain already exists. I have cPanel and it wasn't letting me set the email configuration on the existing domain. I tried creating a new mail subdomain but that didn't seem right with ....

      .container
        .row
          .col-12.col-xl-5
            table#dns-before
              caption.text-center Before
              tr
                th Name
                th TTL
                th Class
                th Type
                th Record
              tr
                td mail.adamkoch.com.
                td 14400
                td IN
                td CNAME
                td adamkoch.com
              tr
                td adamkoch.com.
                td 14400
                td IN
                td MX	
                td
                  | Priority: 0
                  br
                  | Destination: adamkoch.com
          .col-xl-2.text-center
            i.fas.fa-angle-double-right#dns-arrows
          .col-12.col-xl-5
            table#dns-after
              caption.text-center After
              tr
                th Name
                th TTL
                th Class
                th Type
                th Record
              tr
                td mail.adamkoch.com.
                td 14400
                td IN
                td A
                td 192.185.57.80
              tr
                td adamkoch.com.
                td 14400
                td IN
                td MX	
                td
                  | Priority: 0
                  br
                  | Destination: mail.adamkoch.com
      
      .aside Ok, I've been delaying this post for a long time so the next few parts are very thin.

      h5 Web Server Settings

      p Netlify does most of the work. Follow the directions 
        a(href="https://docs.netlify.com/domains-https/custom-domains/configure-external-dns/#configure-an-apex-domain") here
        |. The only "gotcha" was I originally had "www.adamkoch.com" as the A record instead of "adamkoch.com". Not a big deal and easy to rectify.

      h2 Results
      p Since I really enjoy learning this has been awesome. 

      h2 Conclusion
      p If you have a chance to learn something new, then do it! 

    script(type="module").
      import _ from 'lodash'
      import _debug from 'debug'
      const debug = _debug('aakoch:pugAnimation')
      
      jQuery(() => {
        $("#bandwagonLink").one("mouseenter", function() {
          $(this).fadeOut(2000);
        });

        const pugImg = $('#pugImg')
        const woofs = {
          0: $('#woof1'),
          1: $('#woof2')
        }
        let canMove = true;
        let rotateLeft = true;

        const element = pugImg[0]
        let start, previousTimeStamp, x, y;

        const debouncedMovePug = _.debounce(movePug, 10)
        const debouncedUpdateCoordinates = _.debounce(updateCoordinates, 30)
        
        function updateCoordinates(event) {
          if (process.env.NODE_ENV !== 'production') console.debug("inside updateCoordinates")
          if (canMove) {
            x = event.pageX
            y = event.pageY
            movePug()
          }
        }

        function movePug() {
          if (process.env.NODE_ENV !== 'production') console.log(process.env.NODE_ENV)
          if (process.env.NODE_ENV !== 'production') console.debug("inside movePug")
          if (canMove) {
            if (process.env.NODE_ENV !== 'production') console.log(parseInt(pugImg.css("left"), 10) + ',' + parseInt(pugImg.css("top"), 10) + ' -> ' + x + ',' + y);
            let distX = x - parseInt(pugImg.css("left"), 10)
            let distY = y - parseInt(pugImg.css("top"), 10)
            let dist = distX + distY

            let fromTransform = 'translate(0px, 0px)'
            if (process.env.NODE_ENV !== 'production') console.log(\`fromTransform=\${fromTransform}\`)
            let toTransform = 'translate(' + distX + 'px, ' + distY + 'px)'
            if (process.env.NODE_ENV !== 'production') console.log(\`toTransform=\${toTransform}\`)
            $.keyframe.define({
                name: 'move',
                from: {
                    'transform': fromTransform
                },
                to: {
                    'transform': toTransform
                }
            });
            pugImg.resetKeyframe();
            if (process.env.NODE_ENV !== 'production') console.debug("calling playKeyframe")
            pugImg.playKeyframe(
                'move 1s ease-in-out .1s forwards',
                function() {
                  if (process.env.NODE_ENV !== 'production') console.log("inside end of move")

                  canMove = true;
                  pugImg.css("left", x + "px")
                  pugImg.css("top", y + "px")
                  pugImg.css("animation", "none")

                  let barkTwice = Math.floor(Math.random() * 3) > 0;

                  pugImg.resetKeyframe();
                  if (barkTwice) {
                    pugImg.playKeyframe('bark2 .7s linear 0s forwards')
                  }
                  else {
                    pugImg.playKeyframe('bark .3s linear 0s forwards')
                  }

                  rotateLeft = !rotateLeft

                  let keyframeIdx = Math.floor(Math.random() * 2)
                  const currentX = x
                  const currentY = y
                  function go(i, keyframeIdx) {
                    if (process.env.NODE_ENV !== 'production') console.debug("inside go")

                    woofs[i].css("left", (currentX+15) + "px")
                    woofs[i].css("top", (currentY-15) + "px")

                    woofs[i].playKeyframe('woof' + keyframeIdx + ' .9s ease-out 0s forwards')
                  }

                  go(0, keyframeIdx)
                  if (barkTwice) {
                    setTimeout(function () {
                      woofs[1].show().css("visibility", "visible") 
                      go(1, keyframeIdx)
                    }, 300)
                  }

                }
            );

            canMove = false
          }
        }

        $("#pug")
          .mousemove(function (event) {
            debouncedUpdateCoordinates(event)
          })
          .mouseenter(function (event) {
              canMove = true;
              woofs[0].show().css("visibility", "visible") 
              pugImg.fadeIn(1000, function () {
            });
          })
          .mouseleave(function (event) {
            canMove = false;
            pugImg.fadeOut(1000);
          });
          
          pugImg.css("top", "100px")
          pugImg.css("left", "-110px")
          
          woofs[0].css("top", "100px")
          woofs[0].css("left", "-110px")
          
          woofs[1].css("top", "100px")
          woofs[1].css("left", "-110px")
      });`, [])


};
