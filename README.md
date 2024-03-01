<p align="center">
<img alt="Wispar" src= "https://github.com/Scriptbash/Wispar/blob/main/assets/icon/icon.png?raw=true" width="100">
</p>
<h3 align="center">Stay up-to-date with articles in your field of study!</h3>
<p align="center">
<a href="https://github.com/Scriptbash/Wispar/actions/workflows/build.yml">
    <img alt="GitHub Workflow Status" src="https://github.com/Scriptbash/Wispar/actions/workflows/build.yml/badge.svg">
</a>
<a href="https://hosted.weblate.org/engage/wispar/">
<img src="https://hosted.weblate.org/widget/wispar/svg-badge.svg" alt="Translation status" />
</a>
</br></br>
<a href='https://ko-fi.com/A0A6ME7SJ' target='_blank'>
  <img height='32' style='border:0px;height:32px;' src='https://storage.ko-fi.com/cdn/kofi1.png?v=3' border='0' alt='Buy Me a Coffee at ko-fi.com'>
</a>
</p>

---

## Screenshots

| Followed journals (dark)                           | Search results (light)                                  | Journal details (light)                                      | Abstract (dark)                                    |
|----------------------------------------------------|---------------------------------------------------------|--------------------------------------------------------------|----------------------------------------------------|
| ![Journals](screenshots/dark_android_journals.png) | ![Search](screenshots/light_android_search_results.png) | ![JournalDetails](screenshots/light_ios_journal_details.png) | ![abstract](screenshots/dark_android_abstract.png) |


## Description
<p align="justify">
Wispar is a user-friendly and privacy-friendly Android/iOS app that seamlessly searches scientific journals using the Crossref API. Stay updated on your preferred journals by following them and receive new article abstracts in your main feed. No account required. The integration of Unpaywall ensures convenient access to open-access articles, while EZproxy helps overcome subscription barriers.
    
<b>Wispar is still under development and is not ready yet. APK files can be obtained from the workflow artifacts (must be signed in).</b>    
</p>

## Features overview
<ul>
    <li> [x] Search and follow journals</li>
    <li> [ ] Download articles for offline access</li>
    <li> [x] EZproxy and Unpaywall integration</li>
    <li> [x] Send articles to Zotero</li>
    <li> [x] Share articles</li>
</ul>

## Translations

<p align ="justify">
Wispar uses Weblate to manage translations. You can find the hosted instance at <a href="https://hosted.weblate.org/engage/wispar/">https://hosted.weblate.org/engage/wispar/</a>
</br></br>Translation status:
</p>

<a href="https://hosted.weblate.org/engage/wispar/">
<img src="https://hosted.weblate.org/widget/wispar/multi-auto.svg" alt="Translation status" />
</a>

## Contribute
<p align ="justify">

</p>


## Help
<p align ="justify">
If you run into any issue while using Wispar, have a question or want to share your feedback, please open an issue here : https://github.com/Scriptbash/Wispar/issues
</p>

## Credits
<ul>
    <li><a href="https://libproxy-db.org/" target='_blank'>Library Proxy URL Database</a></li>
    <li><a href="https://unpaywall.org/" target='_blank'>Unpaywall</a></li>
    <li><a href="https://www.crossref.org/" target='_blank'>Crossref</a></li>
</ul>

## FAQ
 <b>Q</b>: The journal subjects are missing or are incorrect</br>
<b>A</b>: This is a problem with the Crossref API that originates from Scopus. The subjects metadata from Crossref may be removed in the future though according to this <a href="https://community.crossref.org/t/retrieve-subjects-and-subject-from-journals-and-works/2403/6" target="_blank">thread</a>. 

<b>Q</b>: My institution's EZproxy URL is missing or is incorrect</br>
<b>A</b>: If you can view the list of proxies correctly in the app but notice that your institution is missing or has an incorrect URL, please report the issue to the EZproxy-db by opening a new <a href="https://github.com/tom5760/ezproxy-db/issues/new/choose" target="_blank">issue</a> in their repository. Otherwise, please open a new issue in Wispar's repository. 
