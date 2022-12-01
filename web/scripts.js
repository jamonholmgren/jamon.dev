// Add your scripts here! They'll be loaded at the top of the page, right after the <body> tag.

/**
 * Given a Twitter ID, returns HTML for an embedded tweet.
 *
 * use like this:
 *
 * <div class="twitter-embed" data-tweet-id="1234567890"></div>
 */
function twitterEmbed(tweetId) {
  return `<div>
      <div
        class="twitter-tweet twitter-tweet-rendered"
        style="
          display: flex;
          max-width: 550px;
          width: 100%;
          margin-top: 10px;
          margin-bottom: 10px;
        "
      >
        <iframe
          id="twitter-widget-0"
          scrolling="no"
          frameborder="0"
          allowtransparency="true"
          allowfullscreen="true"
          class=""
          style="
            position: static;
            visibility: visible;
            width: 550px;
            height: 809px;
            display: block;
            flex-grow: 1;
          "
          title="Twitter Tweet"
          src="https://platform.twitter.com/embed/Tweet.html?dnt=false&amp;embedId=twitter-widget-0&amp;features=eyJ0ZndfdGltZWxpbmVfbGlzdCI6eyJidWNrZXQiOlsibGlua3RyLmVlIiwidHIuZWUiLCJ0ZXJyYS5jb20uYnIiLCJ3d3cubGlua3RyLmVlIiwid3d3LnRyLmVlIiwid3d3LnRlcnJhLmNvbS5iciJdLCJ2ZXJzaW9uIjpudWxsfSwidGZ3X2hvcml6b25fdGltZWxpbmVfMTIwMzQiOnsiYnVja2V0IjoidHJlYXRtZW50IiwidmVyc2lvbiI6bnVsbH0sInRmd190d2VldF9lZGl0X2JhY2tlbmQiOnsiYnVja2V0Ijoib24iLCJ2ZXJzaW9uIjpudWxsfSwidGZ3X3JlZnNyY19zZXNzaW9uIjp7ImJ1Y2tldCI6Im9uIiwidmVyc2lvbiI6bnVsbH0sInRmd19jaGluX3BpbGxzXzE0NzQxIjp7ImJ1Y2tldCI6ImNvbG9yX2ljb25zIiwidmVyc2lvbiI6bnVsbH0sInRmd190d2VldF9yZXN1bHRfbWlncmF0aW9uXzEzOTc5Ijp7ImJ1Y2tldCI6InR3ZWV0X3Jlc3VsdCIsInZlcnNpb24iOm51bGx9LCJ0Zndfc2Vuc2l0aXZlX21lZGlhX2ludGVyc3RpdGlhbF8xMzk2MyI6eyJidWNrZXQiOiJpbnRlcnN0aXRpYWwiLCJ2ZXJzaW9uIjpudWxsfSwidGZ3X2V4cGVyaW1lbnRzX2Nvb2tpZV9leHBpcmF0aW9uIjp7ImJ1Y2tldCI6MTIwOTYwMCwidmVyc2lvbiI6bnVsbH0sInRmd19kdXBsaWNhdGVfc2NyaWJlc190b19zZXR0aW5ncyI6eyJidWNrZXQiOiJvbiIsInZlcnNpb24iOm51bGx9LCJ0ZndfdmlkZW9faGxzX2R5bmFtaWNfbWFuaWZlc3RzXzE1MDgyIjp7ImJ1Y2tldCI6InRydWVfYml0cmF0ZSIsInZlcnNpb24iOm51bGx9LCJ0Zndfc2hvd19ibHVlX3ZlcmlmaWVkX2JhZGdlIjp7ImJ1Y2tldCI6Im9uIiwidmVyc2lvbiI6bnVsbH0sInRmd190d2VldF9lZGl0X2Zyb250ZW5kIjp7ImJ1Y2tldCI6Im9uIiwidmVyc2lvbiI6bnVsbH19&amp;frame=false&amp;hideCard=false&amp;hideThread=false&amp;id=${tweetId}&amp;lang=en&amp;origin=https%3A%2F%2Fjamonholmgren.com%2Fnow&amp;sessionId=eea5ec405f7fe8776c2abefb8780ffb847a991b5&amp;theme=light&amp;widgetsVersion=a3525f077c700%3A1667415560940&amp;width=550px"
          data-tweet-id="${tweetId}"
        ></iframe>
      </div>
    </div>`;
}

// Find all elements with class of "twitter-embed" and replace them with the embedded tweet.
document.querySelectorAll(".twitter-embed").forEach((el) => {
  el.innerHTML = twitterEmbed(el.dataset.tweetId);
});
