/* ─────────────────────────────────────────
   Z SPEED LANDING PAGE — script.js
   Features:
   - AR / EN language switcher
   - Dark / Light theme toggle
   - Navbar scroll effect
   - Particle canvas animation
   - IntersectionObserver scroll reveals
   - Animated counter numbers
   - Mobile hamburger menu
   - Back-to-top button
   ───────────────────────────────────────── */

(() => {
  'use strict';

  // ─── STATE ───────────────────────────────
  let currentLang  = 'en';
  let currentTheme = 'dark';
  let countersStarted = false;

  // ─── ELEMENTS ────────────────────────────
  const html       = document.documentElement;
  const navbar     = document.getElementById('navbar');
  const langBtn    = document.getElementById('langBtn');
  const langLabel  = document.getElementById('langLabel');
  const themeBtn   = document.getElementById('themeBtn');
  const themeIcon  = document.getElementById('themeIcon');
  const hamburger  = document.getElementById('hamburger');
  const navLinks   = document.getElementById('navLinks');
  const backToTop  = document.getElementById('backToTop');
  const canvas     = document.getElementById('particleCanvas');

  // ─── LANGUAGE SWITCHER ───────────────────
  function applyLang(lang) {
    currentLang = lang;
    html.lang = lang;
    html.dir  = lang === 'ar' ? 'rtl' : 'ltr';
    langLabel.textContent = lang === 'ar' ? 'English' : 'عربي';

    document.querySelectorAll('[data-en][data-ar]').forEach(el => {
      const txt = el.getAttribute(`data-${lang}`);
      if (txt) el.textContent = txt;
    });

    // Store preference
    try { localStorage.setItem('zspeed_lang', lang); } catch(e) {}
  }

  langBtn.addEventListener('click', () => {
    applyLang(currentLang === 'en' ? 'ar' : 'en');
  });

  // ─── THEME TOGGLE ────────────────────────
  function applyTheme(theme) {
    currentTheme = theme;
    html.setAttribute('data-theme', theme);
    themeIcon.textContent = theme === 'dark' ? '☀️' : '🌙';
    try { localStorage.setItem('zspeed_theme', theme); } catch(e) {}
  }

  themeBtn.addEventListener('click', () => {
    applyTheme(currentTheme === 'dark' ? 'light' : 'dark');
  });

  // ─── RESTORE PREFERENCES ─────────────────
  try {
    const savedLang  = localStorage.getItem('zspeed_lang');
    const savedTheme = localStorage.getItem('zspeed_theme');
    if (savedLang)  applyLang(savedLang);
    if (savedTheme) applyTheme(savedTheme);
  } catch(e) {}

  // ─── NAVBAR SCROLL ───────────────────────
  function onScroll() {
    // Sticky navbar
    navbar.classList.toggle('scrolled', window.scrollY > 50);

    // Back to top visibility
    backToTop.classList.toggle('visible', window.scrollY > 400);
  }
  window.addEventListener('scroll', onScroll, { passive: true });

  // ─── BACK TO TOP ─────────────────────────
  backToTop.addEventListener('click', () => {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  });

  // ─── HAMBURGER MENU ──────────────────────
  hamburger.addEventListener('click', () => {
    const open = hamburger.classList.toggle('open');
    navLinks.classList.toggle('open', open);
    document.body.style.overflow = open ? 'hidden' : '';
  });

  // Close mobile menu on nav link click
  document.querySelectorAll('.nav-link').forEach(link => {
    link.addEventListener('click', () => {
      hamburger.classList.remove('open');
      navLinks.classList.remove('open');
      document.body.style.overflow = '';
    });
  });

  // ─── SMOOTH SCROLL FOR NAV LINKS ─────────
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', e => {
      const target = document.querySelector(anchor.getAttribute('href'));
      if (target) {
        e.preventDefault();
        const offset = 80; // navbar height
        const top = target.getBoundingClientRect().top + window.scrollY - offset;
        window.scrollTo({ top, behavior: 'smooth' });
      }
    });
  });

  // ─── INTERSECTION OBSERVER: REVEAL ───────
  const revealObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
        revealObserver.unobserve(entry.target);
      }
    });
  }, { threshold: 0.1, rootMargin: '0px 0px -40px 0px' });

  document.querySelectorAll('.reveal').forEach(el => revealObserver.observe(el));

  // ─── COUNTER ANIMATION ───────────────────
  function animateCounter(el) {
    const target  = parseInt(el.dataset.target, 10);
    const suffix  = el.dataset.suffix || '';
    const duration = 2000; // ms
    const start   = performance.now();
    const easeOut = t => 1 - Math.pow(1 - t, 3);

    function step(now) {
      const progress = Math.min((now - start) / duration, 1);
      const value    = Math.floor(easeOut(progress) * target);
      el.textContent = value.toLocaleString() + suffix;
      if (progress < 1) requestAnimationFrame(step);
    }
    requestAnimationFrame(step);
  }

  const statsObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting && !countersStarted) {
        countersStarted = true;
        document.querySelectorAll('.counter-num').forEach(animateCounter);
        statsObserver.disconnect();
      }
    });
  }, { threshold: 0.3 });

  const statsSection = document.getElementById('stats');
  if (statsSection) statsObserver.observe(statsSection);

  // ─── PARTICLE CANVAS ─────────────────────
  (function initParticles() {
    if (!canvas) return;
    const ctx = canvas.getContext('2d');

    let particles = [];
    let animId;

    function resize() {
      canvas.width  = window.innerWidth;
      canvas.height = window.innerHeight;
    }

    function createParticle() {
      return {
        x:    Math.random() * canvas.width,
        y:    Math.random() * canvas.height,
        vx:   (Math.random() - 0.5) * 0.4,
        vy:   (Math.random() - 0.5) * 0.4 - 0.1,
        size: Math.random() * 2 + 0.5,
        alpha:Math.random() * 0.5 + 0.1,
        color:Math.random() > 0.5 ? '#F35535' : '#E17421',
      };
    }

    function init() {
      resize();
      const count = Math.min(80, Math.floor((canvas.width * canvas.height) / 12000));
      particles = Array.from({ length: count }, createParticle);
    }

    function draw() {
      ctx.clearRect(0, 0, canvas.width, canvas.height);

      // Draw connections
      particles.forEach((p, i) => {
        for (let j = i + 1; j < particles.length; j++) {
          const q = particles[j];
          const dx = p.x - q.x;
          const dy = p.y - q.y;
          const dist = Math.sqrt(dx * dx + dy * dy);
          if (dist < 120) {
            ctx.beginPath();
            ctx.moveTo(p.x, p.y);
            ctx.lineTo(q.x, q.y);
            ctx.strokeStyle = `rgba(243,85,53,${(1 - dist / 120) * 0.12})`;
            ctx.lineWidth = 0.6;
            ctx.stroke();
          }
        }
      });

      // Draw particles
      particles.forEach(p => {
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
        ctx.fillStyle = p.color;
        ctx.globalAlpha = p.alpha;
        ctx.fill();
        ctx.globalAlpha = 1;
      });
    }

    function update() {
      particles.forEach(p => {
        p.x += p.vx;
        p.y += p.vy;

        // Wrap around edges
        if (p.x < -10) p.x = canvas.width + 10;
        if (p.x > canvas.width + 10) p.x = -10;
        if (p.y < -10) p.y = canvas.height + 10;
        if (p.y > canvas.height + 10) p.y = -10;
      });
    }

    function loop() {
      draw();
      update();
      animId = requestAnimationFrame(loop);
    }

    // Pause when hero is off-screen (perf)
    const heroEl = document.getElementById('hero');
    const heroObs = new IntersectionObserver(entries => {
      if (entries[0].isIntersecting) {
        cancelAnimationFrame(animId);
        loop();
      } else {
        cancelAnimationFrame(animId);
      }
    }, { threshold: 0 });
    if (heroEl) heroObs.observe(heroEl);

    window.addEventListener('resize', () => {
      resize();
      cancelAnimationFrame(animId);
      init();
      loop();
    });

    init();
    loop();
  })();

  // ─── HERO BADGE PARALLAX ─────────────────
  let ticking = false;
  window.addEventListener('scroll', () => {
    if (!ticking) {
      requestAnimationFrame(() => {
        const scrolled = window.scrollY;
        const heroContent = document.querySelector('.hero-content');
        const heroPhone   = document.querySelector('.hero-phone');
        if (heroContent && scrolled < window.innerHeight) {
          heroContent.style.transform = `translateY(${scrolled * 0.08}px)`;
        }
        if (heroPhone && scrolled < window.innerHeight) {
          heroPhone.style.transform = `translateY(${scrolled * 0.05 - 0}px)`;
        }
        ticking = false;
      });
      ticking = true;
    }
  }, { passive: true });

  // ─── FEATURE CARD GLOW ON HOVER ──────────
  document.querySelectorAll('.feature-card, .service-card, .step').forEach(card => {
    card.addEventListener('mousemove', e => {
      const rect = card.getBoundingClientRect();
      const x = ((e.clientX - rect.left) / rect.width) * 100;
      const y = ((e.clientY - rect.top) / rect.height) * 100;
      card.style.setProperty('--mouse-x', `${x}%`);
      card.style.setProperty('--mouse-y', `${y}%`);
    });
  });

  // ─── ACTIVE NAV LINK ON SCROLL ───────────
  const sections = document.querySelectorAll('section[id]');
  const navItems = document.querySelectorAll('.nav-link');

  const sectionObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        navItems.forEach(item => {
          item.style.color = '';
          if (item.getAttribute('href') === `#${entry.target.id}`) {
            item.style.color = 'var(--primary)';
          }
        });
      }
    });
  }, { threshold: 0.4 });

  sections.forEach(section => sectionObserver.observe(section));

  // ─── TRIGGER INITIAL ANIMATIONS ──────────
  // Ensure hero animations run after load
  window.addEventListener('load', () => {
    document.querySelectorAll('.animate-fade-up').forEach(el => {
      el.style.animationPlayState = 'running';
    });
  });

})();
