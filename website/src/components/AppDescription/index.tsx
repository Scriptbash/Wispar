import React from 'react';
import clsx from 'clsx';
import ScreenshotCarousel from '../ScreenshotCarousel';
import styles from './styles.module.css';

export default function HeroSection() {
  return (
    <section className={clsx('container', styles.heroSection)}>
      <div className={styles.heroContent}>
        <div className={styles.heroTextWrapper}>
          <p className={styles.heroText}>
            Wispar (Wisdom + Scholar) is an Android and iOS app designed to make academic
            research simpler, faster, and less overwhelming. Follow the journals
            and topics you care about, get notified when new articles appear, and
            read them offline in a clean, distraction-free interface.
          </p>
        </div>
        <div className={styles.heroCarouselWrapper}>
          <ScreenshotCarousel />
        </div>
      </div>
    </section>
  );
}
