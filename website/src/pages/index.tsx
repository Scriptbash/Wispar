import type {ReactNode} from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import HomepageFeatures from '@site/src/components/HomepageFeatures';
import Heading from '@theme/Heading';
import HeroText from '@site/src/components/AppDescription';

import styles from './index.module.css';

function HomepageHeader() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <header className={clsx('hero hero--primary', styles.heroBanner)}>
      <div className="container">
        <div className={styles.logoAndTitle}>
          <img
            src="/img/wispar.png"
            alt="Wispar Logo"
            className={styles.logo}
          />
          <Heading as="h1" className="hero__title">
            {siteConfig.title}
          </Heading>
        </div>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <div className={styles.buttons} style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <Link
            className="button button--secondary button--lg"
            to="#download"
          >
            Get it now!
          </Link>
          <iframe
            src="https://ghbtns.com/github-btn.html?user=Scriptbash&repo=Wispar&type=star&count=true&size=large"
            width="150"
            height="30"
            title="GitHub"
            style={{ verticalAlign: 'middle', marginRight: '10px' }}
          ></iframe>
        </div>
      </div>
    </header>
  );
}


function AppStoreSection() {
  return (
    <section id="download" className={styles.appStores}>
      <div className="container text--center" style={{ padding: '40px 0' }}>
        <Heading as="h1" style={{ marginBottom: '30px' }}>Get Wispar Now</Heading>
        <div className={styles.storeButtons} style={{ display: 'flex', flexWrap: 'wrap', justifyContent: 'center', alignItems: 'center', gap: '15px' }}>          
          <a href="https://play.google.com/store/apps/details?id=app.wispar.wispar">
            <img
              src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg"
              alt="Get it on Google Play"
              style={{ height: '50px' }}
            />
          </a>
          <a href="https://apps.apple.com/us/app/wispar/id6741366984">
            <img
              src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg"
              alt="Download on the App Store"
              style={{ height: '50px' }}
            />
          </a>
          <a href="https://f-droid.org/packages/app.wispar.wispar">
            <img
              src="https://upload.wikimedia.org/wikipedia/commons/9/96/%22Get_it_on_F-droid%22_Badge.png"
              alt="Download on F-Droid"
              style={{ height: '50px' }}
            />
          </a>
          <a href="https://github.com/Scriptbash/Wispar/releases/latest">
            <img 
              src="https://custom-icon-badges.demolab.com/badge/Windows-0078D6?logo=windows11&logoColor=white" 
              alt="Download for Windows"
              style={{ height: '50px', borderRadius: '8px' }}
            />
          </a>
          <a href="https://github.com/Scriptbash/Wispar/releases/latest">
            <img 
              src="https://img.shields.io/badge/macOS-000000?style=flat&logo=apple&logoColor=white" 
              alt="Download for macOS"
              style={{ height: '50px', borderRadius: '8px' }}
            />
          </a>
        </div>
      </div>
    </section>
  );
}


export default function Home(): ReactNode {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout
      title={`${siteConfig.title} - Research companion`}
      description="Wispar is a privacy-friendly research companion for exploring academic journals and scientific articles. Powered by Crossref and OpenAlex APIs, it lets you follow journals and get the latest research abstracts in your feed — all without creating an account.">
      <HomepageHeader />
      <main>
        <HeroText />
        <HomepageFeatures />
        <AppStoreSection />
      </main>
    </Layout>
  );
}
