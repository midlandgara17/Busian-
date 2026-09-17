/* =========================================================
   BUSIAN APPLICATION FOUNDATION
   ========================================================= */

(() => {
  "use strict";

  const BUSIAN = {
    version: "1.0.0",

    init() {
      this.setCurrentNavigation();
      this.setupInteractiveLinks();
      this.setupCartCount();
    },

    /* -------------------------------------------------------
       CURRENT NAVIGATION
       ------------------------------------------------------- */

    setCurrentNavigation() {
      const currentPage =
        window.location.pathname.split("/").pop() || "index.html";

      const navigationLinks =
        document.querySelectorAll(".nav-link");

      navigationLinks.forEach((link) => {
        const href = link.getAttribute("href");

        if (!href) return;

        const linkPage = href.split("/").pop();

        const isHome =
          (currentPage === "" || currentPage === "index.html") &&
          linkPage === "index.html";

        const isCurrent =
          currentPage !== "index.html" &&
          currentPage === linkPage;

        if (isHome || isCurrent) {
          link.classList.add("active");
          link.setAttribute("aria-current", "page");
        } else {
          link.classList.remove("active");
          link.removeAttribute("aria-current");
        }
      });
    },

    /* -------------------------------------------------------
       INTERACTIVE LINKS
       ------------------------------------------------------- */

    setupInteractiveLinks() {
      const links =
        document.querySelectorAll("a[href]");

      links.forEach((link) => {
        link.addEventListener("click", () => {
          link.classList.add("is-pressed");

          window.setTimeout(() => {
            link.classList.remove("is-pressed");
          }, 180);
        });
      });
    },

    /* -------------------------------------------------------
       CART
       ------------------------------------------------------- */

    setupCartCount() {
      const cartCount =
        document.querySelector(".cart-count");

      if (!cartCount) return;

      const savedCart =
        localStorage.getItem("busian_cart_count");

      const count =
        Number.parseInt(savedCart || "0", 10);

      cartCount.textContent =
        Number.isFinite(count) && count >= 0
          ? count
          : "0";
    },

    updateCartCount(count) {
      const safeCount =
        Math.max(0, Number.parseInt(count, 10) || 0);

      localStorage.setItem(
        "busian_cart_count",
        String(safeCount)
      );

      const cartCount =
        document.querySelector(".cart-count");

      if (cartCount) {
        cartCount.textContent = safeCount;
      }
    }
  };

  document.addEventListener("DOMContentLoaded", () => {
    BUSIAN.init();
  });

  window.BUSIAN = BUSIAN;
})();
