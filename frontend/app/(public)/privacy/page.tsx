import StaticPageLayout from '@/components/layout/StaticPageLayout'

export default function PrivacyPage() {
  return (
    <StaticPageLayout 
      title="Privacy Policy" 
      description="Learn how we collect, use, and protect your personal information."
      lastUpdated="January 1, 2025"
    >
      <h2>1. Information We Collect</h2>
      
      <h3>Personal Information</h3>
      <p>We collect information you provide directly to us, such as:</p>
      <ul>
        <li>Account registration information (email, password)</li>
        <li>Profile information (name, preferences, timezone)</li>
        <li>Payment information (processed securely through Stripe)</li>
        <li>Communication data (support tickets, feedback)</li>
      </ul>

      <h3>Device and Sensor Data</h3>
      <p>When you connect IoT devices to our platform, we collect:</p>
      <ul>
        <li>Sensor readings (temperature, humidity, pH, etc.)</li>
        <li>Device status and configuration data</li>
        <li>Device connection logs and timestamps</li>
        <li>Command and control data</li>
      </ul>

      <h3>Usage Information</h3>
      <p>We automatically collect certain information about your use of our service:</p>
      <ul>
        <li>Log data (IP addresses, browser type, pages visited)</li>
        <li>Usage patterns and feature interactions</li>
        <li>Performance and error data</li>
      </ul>

      <h2>2. How We Use Your Information</h2>
      <p>We use the information we collect to:</p>
      <ul>
        <li>Provide, maintain, and improve our services</li>
        <li>Process transactions and manage subscriptions</li>
        <li>Send you technical notices and support messages</li>
        <li>Analyze usage patterns to enhance user experience</li>
        <li>Detect and prevent fraud and abuse</li>
        <li>Comply with legal obligations</li>
      </ul>

      <h2>3. Data Sharing and Disclosure</h2>
      
      <h3>We do not sell your personal data.</h3>
      <p>We may share information in the following circumstances:</p>
      <ul>
        <li><strong>Service Providers:</strong> Third-party services that help us operate (hosting, payment processing)</li>
        <li><strong>Legal Requirements:</strong> When required by law or to protect our rights</li>
        <li><strong>Business Transfers:</strong> In connection with mergers, acquisitions, or asset sales</li>
        <li><strong>Consent:</strong> With your explicit permission</li>
      </ul>

      <h2>4. Data Security</h2>
      <p>We implement appropriate security measures to protect your information:</p>
      <ul>
        <li>Encryption in transit and at rest</li>
        <li>Regular security audits and monitoring</li>
        <li>Access controls and authentication</li>
        <li>Secure data centers and infrastructure</li>
      </ul>

      <h2>5. Data Retention</h2>
      <p>We retain your information for as long as necessary to:</p>
      <ul>
        <li>Provide our services to you</li>
        <li>Comply with legal obligations</li>
        <li>Resolve disputes and enforce agreements</li>
      </ul>
      <p>Device data is typically retained for 2 years for analytics purposes, unless you request earlier deletion.</p>

      <h2>6. Your Rights and Choices</h2>
      <p>You have the right to:</p>
      <ul>
        <li>Access and update your personal information</li>
        <li>Delete your account and associated data</li>
        <li>Export your device data</li>
        <li>Opt out of non-essential communications</li>
        <li>Request data portability</li>
      </ul>

      <h2>7. International Data Transfers</h2>
      <p>
        Our services are hosted in secure data centers. If you access our service from outside the hosting region, 
        your information may be transferred internationally. We ensure appropriate safeguards are in place.
      </p>

      <h2>8. Children's Privacy</h2>
      <p>
        Our service is not intended for children under 13. We do not knowingly collect personal information from 
        children under 13. If you believe we have collected such information, please contact us immediately.
      </p>

      <h2>9. Changes to This Policy</h2>
      <p>
        We may update this privacy policy from time to time. We will notify you of any changes by posting the new 
        policy on this page and updating the "last updated" date.
      </p>

      <h2>10. Contact Us</h2>
      <p>
        If you have any questions about this Privacy Policy, please contact us at:
      </p>
      <ul>
        <li>Email: privacy@spacegrow.ai</li>
        <li>Address: [Your Company Address]</li>
      </ul>
    </StaticPageLayout>
  )
}