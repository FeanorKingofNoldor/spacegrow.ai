import StaticPageLayout from '@/components/layout/StaticPageLayout'

export default function CookiesPage() {
  return (
    <StaticPageLayout 
      title="Cookie Policy" 
      description="Learn about how we use cookies and similar technologies on our website."
      lastUpdated="January 1, 2025"
    >
      <h2>1. What Are Cookies</h2>
      <p>
        Cookies are small text files that are stored on your device when you visit our website. They help us 
        provide you with a better experience by remembering your preferences and understanding how you use our service.
      </p>

      <h2>2. Types of Cookies We Use</h2>
      
      <h3>Essential Cookies</h3>
      <p>These cookies are necessary for our website to function properly:</p>
      <ul>
        <li><strong>Authentication:</strong> Keep you logged in to your account</li>
        <li><strong>Security:</strong> Protect against cross-site request forgery</li>
        <li><strong>Preferences:</strong> Remember your theme and language settings</li>
      </ul>

      <h3>Functional Cookies</h3>
      <p>These cookies enhance your experience on our website:</p>
      <ul>
        <li><strong>Theme Preference:</strong> Remember your dark/light mode choice</li>
        <li><strong>Dashboard Layout:</strong> Save your preferred dashboard configuration</li>
        <li><strong>Device Settings:</strong> Remember device groupings and display preferences</li>
      </ul>

      <h3>Analytics Cookies</h3>
      <p>These cookies help us understand how our website is used:</p>
      <ul>
        <li><strong>Usage Analytics:</strong> Track page views and user interactions</li>
        <li><strong>Performance Monitoring:</strong> Identify and fix technical issues</li>
        <li><strong>Feature Usage:</strong> Understand which features are most valuable</li>
      </ul>

      <h2>3. Third-Party Cookies</h2>
      <p>We may use third-party services that set their own cookies:</p>
      
      <h3>Stripe (Payment Processing)</h3>
      <ul>
        <li>Processes payments securely</li>
        <li>Prevents fraudulent transactions</li>
        <li>More info: <a href="https://stripe.com/privacy" className="text-blue-600 dark:text-blue-400">Stripe Privacy Policy</a></li>
      </ul>

      <h3>Analytics Services</h3>
      <ul>
        <li>Help us understand website usage</li>
        <li>Improve user experience</li>
        <li>Anonymous usage statistics only</li>
      </ul>

      <h2>4. Managing Your Cookie Preferences</h2>
      
      <h3>Browser Settings</h3>
      <p>You can control cookies through your browser settings:</p>
      <ul>
        <li><strong>Chrome:</strong> Settings → Privacy and Security → Cookies and other site data</li>
        <li><strong>Firefox:</strong> Preferences → Privacy & Security → Cookies and Site Data</li>
        <li><strong>Safari:</strong> Preferences → Privacy → Manage Website Data</li>
        <li><strong>Edge:</strong> Settings → Cookies and site permissions → Cookies and site data</li>
      </ul>

      <h3>Account Settings</h3>
      <p>
        When logged in, you can manage some cookie preferences in your account settings, including:
      </p>
      <ul>
        <li>Analytics tracking preferences</li>
        <li>Marketing communication cookies</li>
        <li>Optional enhancement cookies</li>
      </ul>

      <h2>5. Impact of Disabling Cookies</h2>
      <p>Disabling certain cookies may affect your experience:</p>
      <ul>
        <li><strong>Essential cookies:</strong> The website may not function properly</li>
        <li><strong>Functional cookies:</strong> You'll need to reset preferences each visit</li>
        <li><strong>Analytics cookies:</strong> No impact on functionality</li>
      </ul>

      <h2>6. Local Storage and Similar Technologies</h2>
      <p>In addition to cookies, we may use:</p>
      <ul>
        <li><strong>Local Storage:</strong> Store theme preferences and dashboard settings</li>
        <li><strong>Session Storage:</strong> Temporary data for the current browser session</li>
        <li><strong>Web Beacons:</strong> Track email open rates (if you subscribe to our newsletter)</li>
      </ul>

      <h2>7. Data Retention</h2>
      <p>Cookie data is retained for different periods:</p>
      <ul>
        <li><strong>Session cookies:</strong> Deleted when you close your browser</li>
        <li><strong>Persistent cookies:</strong> Stored for up to 1 year</li>
        <li><strong>Analytics data:</strong> Aggregated and anonymized after 26 months</li>
      </ul>

      <h2>8. Updates to This Policy</h2>
      <p>
        We may update this Cookie Policy from time to time. Any changes will be posted on this page with an 
        updated revision date. We encourage you to review this policy periodically.
      </p>

      <h2>9. Contact Us</h2>
      <p>
        If you have any questions about our use of cookies, please contact us at:
      </p>
      <ul>
        <li>Email: privacy@spacegrow.ai</li>
        <li>Subject: Cookie Policy Inquiry</li>
      </ul>

      <p>
        <strong>Note:</strong> By continuing to use our website, you consent to our use of cookies as described in this policy.
      </p>
    </StaticPageLayout>
  )
}