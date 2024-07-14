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
          src="https://platform.twitter.com/embed/Tweet.html?dnt=false&amp;embedId=twitter-widget-0&amp;features=eyJ0ZndfdGltZWxpbmVfbGlzdCI6eyJidWNrZXQiOlsibGlua3RyLmVlIiwidHIuZWUiLCJ0ZXJyYS5jb20uYnIiLCJ3d3cubGlua3RyLmVlIiwid3d3LnRyLmVlIiwid3d3LnRlcnJhLmNvbS5iciJdLCJ2ZXJzaW9uIjpudWxsfSwidGZ3X2hvcml6b25fdGltZWxpbmVfMTIwMzQiOnsiYnVja2V0IjoidHJlYXRtZW50IiwidmVyc2lvbiI6bnVsbH0sInRmd190d2VldF9lZGl0X2JhY2tlbmQiOnsiYnVja2V0Ijoib24iLCJ2ZXJzaW9uIjpudWxsfSwidGZ3X3JlZnNyY19zZXNzaW9uIjp7ImJ1Y2tldCI6Im9uIiwidmVyc2lvbiI6bnVsbH0sInRmd19jaGluX3BpbGxzXzE0NzQxIjp7ImJ1Y2tldCI6ImNvbG9yX2ljb25zIiwidmVyc2lvbiI6bnVsbH0sInRmd190d2VldF9yZXN1bHRfbWlncmF0aW9uXzEzOTc5Ijp7ImJ1Y2tldCI6InR3ZWV0X3Jlc3VsdCIsInZlcnNpb24iOm51bGx9LCJ0Zndfc2Vuc2l0aXZlX21lZGlhX2ludGVyc3RpdGlhbF8xMzk2MyI6eyJidWNrZXQiOiJpbnRlcnN0aXRpYWwiLCJ2ZXJzaW9uIjpudWxsfSwidGZ3X2V4cGVyaW1lbnRzX2Nvb2tpZV9leHBpcmF0aW9uIjp7ImJ1Y2tldCI6MTIwOTYwMCwidmVyc2lvbiI6bnVsbH0sInRmd19kdXBsaWNhdGVfc2NyaWJlc190b19zZXR0aW5ncyI6eyJidWNrZXQiOiJvbiIsInZlcnNpb24iOm51bGx9LCJ0ZndfdmlkZW9faGxzX2R5bmFtaWNfbWFuaWZlc3RzXzE1MDgyIjp7ImJ1Y2tldCI6InRydWVfYml0cmF0ZSIsInZlcnNpb24iOm51bGx9LCJ0Zndfc2hvd19ibHVlX3ZlcmlmaWVkX2JhZGdlIjp7ImJ1Y2tldCI6Im9uIiwidmVyc2lvbiI6bnVsbH0sInRmd190d2VldF9lZGl0X2Zyb250ZW5kIjp7ImJ1Y2tldCI6Im9uIiwidmVyc2lvbiI6bnVsbH19&amp;frame=false&amp;hideCard=false&amp;hideThread=false&amp;id=${tweetId}&amp;lang=en&amp;origin=https%3A%2F%2Fjamon.dev%2Fnow&amp;sessionId=eea5ec405f7fe8776c2abefb8780ffb847a991b5&amp;theme=light&amp;widgetsVersion=a3525f077c700%3A1667415560940&amp;width=550px"
          data-tweet-id="${tweetId}"
        ></iframe>
      </div>
    </div>`;
}

// Find all elements with class of "twitter-embed" and replace them with the embedded tweet.
document.querySelectorAll(".twitter-embed").forEach((el) => {
  el.innerHTML = twitterEmbed(el.dataset.tweetId);
});

/**
 * Given a YouTube ID and title, returns HTML for an embedded video.
 */
function youtubeEmbed(youtubeId, title) {
  return `<div class="resp-container">
    <iframe
      style="width:100%;height:100%;"
      title="${title}"
      src="https://www.youtube.com/embed/${youtubeId}"
      frameborder="0"
      allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture"
      allowfullscreen=""
      class="resp-iframe"
    ></iframe>
  </div>`;
}

// Find all elements with class of "youtube-embed" and replace them with the embedded video.
document.querySelectorAll(".youtube-embed").forEach((el) => {
  el.innerHTML = youtubeEmbed(el.dataset.youtubeId, el.innerText);
});

/**
 * Fetches the blog number and updates the badge and localStorage as necessary.
 */
function fetchAndUpdateBlogInfo() {
  // first, if there's no localStorage set, show the badge pre-emptively
  let storedBlogNumber = parseInt(localStorage.getItem("blogNumber"), 10) || 0;

  // shortcut: if the storedBlogNumber is 0, we don't need to fetch
  if (storedBlogNumber === 0) {
    document.getElementById("unread-badge").style.display = "inline";

    // if we're on the blog page, we do need to fetch ... we hack this by setting it to 1
    if (window.location.pathname.startsWith("/blog")) {
      storedBlogNumber = 1;
    }
  }

  // if the storedBlogNumber is still 0, we don't need to fetch
  if (storedBlogNumber === 0) return;

  // OK we need to fetch the blog number
  fetch("/static/blog.json")
    .then((response) => response.json())
    .then((data) => {
      const currentBlogNumber = data.blogNumber;
      updateBadge(currentBlogNumber);

      if (window.location.pathname.startsWith("/blog")) {
        localStorage.setItem("blogNumber", currentBlogNumber.toString());
        updateBadge(0);
      }
    })
    .catch((error) => console.error("Error fetching blog number:", error));
}

/**
 * Updates the navigation badge with the number of new blog posts.
 */
function updateBadge(currentBlogNumber) {
  const storedBlogNumber = parseInt(localStorage.getItem("blogNumber"), 10) || 0;

  const showBadge = currentBlogNumber > storedBlogNumber;

  // // We could update the badge to show something other than "1", but I'd rather not
  // if (showBadge) {
  //   document.getElementById("unread-badge").textContent = currentBlogNumber - storedBlogNumber;
  // }

  document.getElementById("unread-badge").style.display = showBadge ? "inline" : "none";
}

// Call the function on page load
fetchAndUpdateBlogInfo();

if (window.location.pathname.startsWith("/blog")) {
  document.addEventListener("DOMContentLoaded", () => {
    // we'll now gather all the blog post titles and add them to the sub nav
    const articles = document.querySelectorAll("article");
    // grab the titles from the contained h2s and add to the article objects
    // as well as the anchor links
    articles.forEach((article) => {
      const articleLink = article.querySelector("h2 a");
      article.dataset.title = articleLink.textContent;
      article.dataset.anchor = articleLink.href;
      article.dataset.hash = articleLink.hash;
    });

    // get the sub nav nav#blog-years
    const subNav = document.getElementById("blog-years");

    // create a ul for the articles links to live in
    const ul = document.createElement("ul");
    ul.classList.add("articles");

    // the list of years is already in there as <a href='/blog/2023'>2023</a> etc
    // now let's add the articles to the sub nav
    articles.forEach((article) => {
      const hash = article.dataset.hash;
      const fullTitle = article.dataset.title;
      const title = hash.slice(1); // remove the #
      const li = document.createElement("li");
      const a = document.createElement("a");
      a.href = article.dataset.anchor;
      a.textContent = title;
      a.title = fullTitle;
      a.dataset.text = title; // to prevent layout shift on hover

      // on click, set this one to active and remove active from the others
      a.addEventListener("click", (e) => {
        // remove active from all the other links
        ul.querySelectorAll("a").forEach((link) => link.classList.remove("active"));
        // add active to this link
        a.classList.add("active");
        // also hide all articles except this one
        articles.forEach((article) => {
          const articleLink = article.querySelector("h2 a");
          if (articleLink.hash === hash) {
            article.style.display = "block";
          } else {
            article.style.display = "none";
          }
        });
        // prevent "jumping" to the hash, but still update the URL
        e.preventDefault();
        window.history.pushState({}, "", a.href);
      });
      li.appendChild(a);
      ul.appendChild(li);
    });

    // append the ul to the sub nav
    subNav.appendChild(ul);

    // automatically click on the proper link based on the URL hash
    const hash = window.location.hash;
    if (hash) {
      const link = ul.querySelector(`a[href='${hash}']`);
      if (link) link.click();
    }
  });
}
