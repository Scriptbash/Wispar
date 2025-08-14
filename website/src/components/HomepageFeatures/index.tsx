import type {ReactNode} from 'react';
import clsx from 'clsx';
import Heading from '@theme/Heading';
import styles from './styles.module.css';
import { BookOpen, Send, Lock, Globe2, Download, Shield } from 'lucide-react';


type FeatureItem = {
  title: string;
  Svg: React.ReactNode;
  description: ReactNode;
};

const FeatureList: FeatureItem[] = [
  {
    title: 'Custom Feeds',
    Svg: <BookOpen size={48} />,
    description: <>Follow journals and keywords to never miss relevant research.</>,
  },
  {
    title: 'Send to Zotero',
    Svg: <Send size={48} />,
    description: <>Link your Zotero account and send publications directly.</>,
  },
  {
    title: 'Unpaywall & EZproxy',
    Svg: <Lock size={48} />,
    description: <>Get open-access papers or bypass paywalls via EZproxy.</>,
  },
  {
    title: 'Abstract Translations',
    Svg: <Globe2 size={48} />,
    description: <>AI translations for abstracts in your preferred language.</>,
  },
  {
    title: 'Offline Reading',
    Svg: <Download size={48} />,
    description: <>Save articles and PDFs for offline use anywhere.</>,
  },
  {
    title: 'Private & Open Source',
    Svg: <Shield size={48} />,
    description: <>No tracking, no ads, your data stays local.</>,
  },
];



function Feature({title, Svg, description}: FeatureItem) {
  return (
    <div className={clsx('col col--4', styles.featureCard)}>
      <div className={styles.imageWrapper}>{Svg}</div>
      <div className="text--center padding-horiz--md">
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures(): ReactNode {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
