import { Swiper, SwiperSlide } from 'swiper/react';
import { Autoplay, Pagination } from 'swiper/modules';
import 'swiper/css';
import 'swiper/css/pagination';
import styles from './styles.module.css';

export default function ScreenshotCarousel() {
  const screenshots = [
    '/img/screenshots/home.png',
    '/img/screenshots/abstract.png',
    '/img/screenshots/custom_feed.png',
    '/img/screenshots/search.png',
    '/img/screenshots/journals.png',
    '/img/screenshots/saved_queries.png',
    '/img/screenshots/downloads.png',
    '/img/screenshots/settings.png',
  ];

  return (
    <div className={styles.carouselContainer}>
      <Swiper
        modules={[Autoplay, Pagination]}
        spaceBetween={20}
        slidesPerView={1}
        loop
        pagination={{ clickable: true }}
        autoplay={{ delay: 3000, disableOnInteraction: false }}
      >
        {screenshots.map((src, i) => (
          <SwiperSlide key={i}>
            <img
              src={src}
              alt={`Screenshot ${i + 1}`}
              className={styles.carouselImage}
            />
          </SwiperSlide>
        ))}
      </Swiper>
    </div>
  );
}
