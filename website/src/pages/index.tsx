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
        <div className={styles.buttons}>
          <Link
            className="button button--secondary button--lg"
            to="#download"
          >
            Download now!
          </Link>
        </div>
      </div>
    </header>
  );
}


function AppStoreSection() {
  return (
    <section id="download" className={styles.appStores}>
      <div className="container text--center">
        <Heading as="h1">Get Wispar Now</Heading>
        <div className={styles.storeButtons}>
          <a href="https://play.google.com/store/apps/details?id=app.wispar.wispar">
            <img
              src="/img/badges/play_store.png"
              alt="Get it on Google Play"
              style={{ height: '60px', marginRight: '10px', marginBottom: '14px' }}
            />
          </a>
          <a href="https://f-droid.org/packages/app.wispar.wispar">
            <img
              src="/img/badges/f_droid.png"
              alt="Download on F-Droid"
              style={{ height: '90px', marginRight: '10px' }}
            />
          </a>
          <a href="https://apps.apple.com/us/app/wispar/id6741366984">
            <img
              src="/img/badges/app_store.svg"
              alt="Download on the App Store"
              style={{ width: '200px', marginRight: '10px', marginBottom: '14px', marginTop: '14px' }}
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
      description="Description will go into a meta tag in <head />">
      <HomepageHeader />
      <main>
        <HeroText />
        <HomepageFeatures />
        <AppStoreSection />
      </main>
    </Layout>
  );
}
