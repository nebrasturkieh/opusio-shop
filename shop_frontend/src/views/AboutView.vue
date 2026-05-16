<template>
  <div class="about-page">
    <!-- Hero -->
    <div class="about-hero">
      <div class="hero-rule"></div>
      <h1 class="hero-title">THE HOUSE OF OPUSIO</h1>
      <div class="hero-rule"></div>
      <p class="hero-sub">
        Crafted for those who understand that true luxury is earned, not displayed.
      </p>
    </div>

    <div class="about-wrap">
      <!-- Story -->
      <section class="about-section">
        <div class="section-label">Our Story</div>
        <div class="section-body">
          <h2 class="section-title">Born from a Reverence for the Rare</h2>
          <p class="section-text">
            Opusio was founded on a single conviction: that a piece of jewelry should outlast
            trends, outlast seasons — and in time, outlast its maker. We began not with a
            collection, but with a question: what does it mean to create something truly enduring?
          </p>
          <p class="section-text">
            The answer was never about spectacle. It was about silence — the weight of a ring on the
            finger, the cool of gold against warm skin, the way light catches a stone held at just
            the right angle. These are the moments Opusio was built to give.
          </p>
        </div>
      </section>

      <!-- Manifesto -->
      <div class="manifesto">
        <div class="manifesto-rule"></div>
        <blockquote class="manifesto-quote">
          "We do not design jewelry. We design moments that become memory."
        </blockquote>
        <div class="manifesto-rule"></div>
      </div>

      <!-- Craft -->
      <section class="about-section about-section--alt">
        <div class="section-label">Our Craft</div>
        <div class="section-body">
          <h2 class="section-title">Every Detail is a Decision</h2>
          <p class="section-text">
            Each Opusio piece passes through the hands of a single artisan from start to finish.
            There are no assembly lines. No shortcuts. Only the patient repetition of a craft
            refined over generations — soldering, setting, polishing, inspecting — repeated until
            there is nothing left to improve.
          </p>
          <p class="section-text">
            Our ateliers work with traditional lost-wax casting alongside contemporary precision
            tooling, marrying the warmth of hand-finishing with the exactness that modern gemology
            demands.
          </p>
        </div>
      </section>

      <!-- Materials -->
      <section class="about-section">
        <div class="section-label">Our Materials</div>
        <div class="section-body">
          <h2 class="section-title">Sourced with Intention</h2>
          <p class="section-text">
            We work exclusively with 18-karat gold, ethically sourced diamonds certified to the
            Kimberley Process, and coloured gemstones traced to responsible mines. Every material in
            an Opusio piece is chosen not only for beauty, but for integrity.
          </p>
          <div class="material-grid">
            <div class="material-item">
              <div class="material-name">18K Gold</div>
              <div class="material-desc">
                Yellow, white, and rose gold in the purest workable alloys.
              </div>
            </div>
            <div class="material-item">
              <div class="material-name">Diamonds</div>
              <div class="material-desc">
                VS clarity and above, selected by our in-house gemologist.
              </div>
            </div>
            <div class="material-item">
              <div class="material-name">Coloured Stones</div>
              <div class="material-desc">
                Sapphires, emeralds, and rubies of heirloom-grade provenance.
              </div>
            </div>
          </div>
        </div>
      </section>

      <!-- Commitment -->
      <section class="about-section about-section--alt">
        <div class="section-label">Our Commitment</div>
        <div class="section-body">
          <h2 class="section-title">Luxury That Leaves No Debt</h2>
          <p class="section-text">
            True luxury cannot be separated from responsibility. Opusio offsets the carbon footprint
            of every shipment, uses fully recycled packaging, and contributes a percentage of each
            sale to environmental preservation initiatives in the regions where our stones are
            sourced.
          </p>
          <p class="section-text">
            We believe the most beautiful things should also be the most considered.
          </p>
        </div>
      </section>
    </div>
  </div>
</template>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Lora:wght@400;500;600&display=swap');

.about-page {
  background: #fff;
  min-height: 100vh;
  padding-bottom: 120px;
}

/* ── Hero ── */
.about-hero {
  padding: 72px 24px 64px;
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 20px;
}

.hero-rule {
  width: 60px;
  height: 1px;
  background: #b8996a;
}

.hero-title {
  font-family: 'Lora', 'Georgia', serif;
  font-size: clamp(18px, 3vw, 26px);
  font-weight: 400;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  color: #1a1a1a;
  margin: 0;
}

.hero-sub {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  font-style: italic;
  line-height: 1.9;
  color: #6b5b4a;
  max-width: 540px;
  margin: 0;
  letter-spacing: 0.01em;
}

/* ── Wrap ── */
.about-wrap {
  max-width: 880px;
  margin: 0 auto;
  padding: 0 24px;
}

/* ── Sections ── */
.about-section {
  display: grid;
  grid-template-columns: 160px 1fr;
  gap: 40px;
  padding: 52px 0;
  border-top: 1px solid rgba(0, 0, 0, 0.07);
}

.about-section--alt {
  background: transparent;
}

.section-label {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 9px;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  color: #b8996a;
  padding-top: 4px;
}

.section-title {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 16px;
  font-weight: 400;
  letter-spacing: 0.06em;
  color: #1a1a1a;
  margin: 0 0 20px;
}

.section-text {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 13px;
  line-height: 1.95;
  color: #6b5b4a;
  margin: 0 0 16px;
  max-width: 600px;
}

.section-text:last-child {
  margin-bottom: 0;
}

/* ── Manifesto ── */
.manifesto {
  padding: 52px 0;
  border-top: 1px solid rgba(0, 0, 0, 0.07);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 24px;
  text-align: center;
}

.manifesto-rule {
  width: 40px;
  height: 1px;
  background: #b8996a;
}

.manifesto-quote {
  font-family: 'Lora', 'Georgia', serif;
  font-size: clamp(14px, 2vw, 18px);
  font-style: italic;
  font-weight: 400;
  color: #1a1a1a;
  letter-spacing: 0.02em;
  line-height: 1.7;
  max-width: 600px;
  margin: 0;
}

/* ── Materials grid ── */
.material-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 0;
  margin-top: 32px;
  border-top: 1px solid rgba(0, 0, 0, 0.07);
  border-left: 1px solid rgba(0, 0, 0, 0.07);
}

.material-item {
  padding: 24px 20px;
  border-right: 1px solid rgba(0, 0, 0, 0.07);
  border-bottom: 1px solid rgba(0, 0, 0, 0.07);
}

.material-name {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 10px;
  letter-spacing: 0.15em;
  text-transform: uppercase;
  color: #1a1a1a;
  margin-bottom: 8px;
}

.material-desc {
  font-family: 'Lora', 'Georgia', serif;
  font-size: 11px;
  line-height: 1.7;
  color: #6b5b4a;
}

/* ── Responsive ── */
@media (max-width: 640px) {
  .about-section {
    grid-template-columns: 1fr;
    gap: 12px;
  }

  .material-grid {
    grid-template-columns: 1fr;
  }
}
</style>
