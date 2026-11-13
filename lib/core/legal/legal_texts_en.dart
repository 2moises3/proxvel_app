import 'legal_texts.dart';

const LegalDoc _privacyPolicy = LegalDoc('privacidad', "Privacy Policy", [
  LegalBlock.h("1. Who is responsible"),
  LegalBlock.p(
    "Biznovatech S.A.C. (trading as M3Biznovatech), based in Ñaña, Lurigancho-Chosica, Lima, Peru. Email soporte@m3biznovatech.com with any questions about your data.",
  ),
  LegalBlock.h("2. What PROXVEL is and who it is for"),
  LegalBlock.p(
    "PROXVEL recommends destinations in Peru based on your travel preferences. It is intended for adults aged 18 and over. If you are under 18, do not create an account.",
  ),
  LegalBlock.h("3. What data we process and why"),
  LegalBlock.ul([
    "First and last name, email and password: to create and protect your account, sign you in and send you security alerts. Your password is stored in a protected form and nobody, including us, can read it.",
    "Place of residence (department, province and district): profile information. The V3 engine does not use it to rank destinations.",
    "Travel style, interests, preferred weather and crowd tolerance: to generate recommendations. Budget and travel days help with planning and do not affect the V3 ranking.",
    "Favorites, archived destinations and notifications: to show your information in the app.",
    "Reviews (rating, comment and optionally the aspect rated): to show other travelers and improve our model (see section 5).",
    "Profile photo (optional): to display it on your profile.",
    "Security logs (IP address, sign-in attempts, password changes and account deletions): to protect your account and prevent abuse.",
  ]),
  LegalBlock.h("4. Location"),
  LegalBlock.p(
    "If you allow it, your phone uses GPS only to calculate how far you are from a destination. That location stays on your phone and is not stored on our servers.",
  ),
  LegalBlock.h("5. Your reviews and model improvement"),
  LegalBlock.p(
    "Your review is shown to other travelers with your first name and last initial (for example, “Lucía G.”). We may also use your review text and rating without your name to analyze and improve the recommendation model. This is done internally.",
  ),
  LegalBlock.h("6. What we do not do"),
  LegalBlock.ul([
    "We do not sell your data or transfer it to other companies.",
    "We do not display advertising or use analytics or tracking tools.",
    "A statistical model generates the recommendations for informational purposes. They have no legal effect on you.",
  ]),
  LegalBlock.h("7. Who receives your data"),
  LegalBlock.p("Only the providers we need to operate PROXVEL:"),
  LegalBlock.ul([
    "Cloudinary: stores images, including your profile photo. Its servers are outside Peru.",
    "OpenStreetMap: provides the maps. It receives your IP address when you load a map.",
    "Server and database hosting provider (currently a local test server; when we release the app, we will use a cloud provider and identify it here).",
  ]),
  LegalBlock.h("8. How long we keep your data"),
  LegalBlock.ul([
    "Account and preferences: while your account is active.",
    "If you request deletion, we block access immediately. You have 14 days to change your mind by emailing soporte@m3biznovatech.com. After that, we delete your profile, favorites, archived destinations, notifications, photo and residence information, and anonymize your name and email.",
    "Reviews: retained without identifying you to improve the model.",
    "Security logs (IP addresses): retained for up to 90 days and then deleted automatically.",
  ]),
  LegalBlock.h("9. Your rights"),
  LegalBlock.p(
    "You can request access, correction, deletion, objection or portability by emailing soporte@m3biznovatech.com from your account email. We will respond within 20 business days. You can delete your account in the app under Profile > Privacy and legal > My data. If you believe we did not handle your request, you can contact Peru's National Personal Data Protection Authority (Ministry of Justice and Human Rights).",
  ),
  LegalBlock.h("10. Security"),
  LegalBlock.p(
    "We protect your data with protected password storage, encrypted connections, limits on sign-in attempts and session revocation when you change your password. You can also sign out on all devices from your profile. If an incident affects you, we will inform you and notify the authority within the legal deadlines.",
  ),
  LegalBlock.h("11. Changes to this policy"),
  LegalBlock.p(
    "If we make a significant change, we will notify you in the app and ask you to accept it again. We always show the version and the date of the last update.",
  ),
]);

const LegalDoc _termsOfUse = LegalDoc('terminos', "Terms and Conditions", [
  LegalBlock.h("1. Acceptance and age"),
  LegalBlock.p(
    "By creating an account you declare that you are at least 18 and accept these Terms and the Privacy Policy. If you do not agree, do not use PROXVEL.",
  ),
  LegalBlock.h("2. Your account"),
  LegalBlock.p(
    "Provide accurate information and protect your password. You are responsible for what happens on your account. If you suspect someone else is using it, change your password and contact us.",
  ),
  LegalBlock.h("3. Permitted use"),
  LegalBlock.p(
    "Do not attempt to compromise PROXVEL's security, extract data in bulk, impersonate someone or use the app for unlawful purposes.",
  ),
  LegalBlock.h("4. User reviews"),
  LegalBlock.ul([
    "Reviews must express your honest opinion about a real experience. You are responsible for what you write.",
    "Reviews must not be abusive or discriminatory or contain other people's personal information or advertising.",
    "You authorize us to display your reviews in the app, use them without your name to improve the recommendation model (see the Privacy Policy), and hide reviews that violate these rules or are reported by other travelers.",
  ]),
  LegalBlock.h("5. Tourist information"),
  LegalBlock.p(
    "Descriptions, durations, costs, weather and crowd levels in PROXVEL are provided as guidance. Hours, prices, access and safety conditions change. Verify them with official sources before traveling. We do not guarantee accuracy or accept responsibility for travel decisions based solely on the app.",
  ),
  LegalBlock.h("6. Recommendations"),
  LegalBlock.p(
    "A statistical model generates recommendations using your preferences, weather and visitor data, and reviews. Use your own judgment.",
  ),
  LegalBlock.h("7. Beta version"),
  LegalBlock.p(
    "PROXVEL is in beta. It may contain errors, change without notice or be temporarily unavailable.",
  ),
  LegalBlock.h("8. Intellectual property"),
  LegalBlock.p(
    "The app, brand, design and code belong to Biznovatech S.A.C. Third-party data and maps retain their own licenses (see Sources and licenses).",
  ),
  LegalBlock.h("9. Account suspension"),
  LegalBlock.p(
    "We may suspend or close accounts that violate these Terms. You can delete your account from the app at any time.",
  ),
  LegalBlock.h("10. Changes"),
  LegalBlock.p(
    "We may update these Terms. If a change is significant, we will notify you and ask you to accept them again.",
  ),
  LegalBlock.h("11. Governing law and contact"),
  LegalBlock.p(
    "Peruvian law applies. Email soporte@m3biznovatech.com with questions. Responsible party: Biznovatech S.A.C. (trading as M3Biznovatech), based in Ñaña, Lurigancho-Chosica, Lima, Peru.",
  ),
]);

const LegalDoc _myData = LegalDoc('mis-datos', "My data and account deletion", [
  LegalBlock.h("What data we keep about you"),
  LegalBlock.ul([
    "Account: first and last name, email, protected password and residence.",
    "Travel preferences: interests, weather, crowd tolerance, budget and travel days.",
    "Your activity: favorites, archived destinations, notifications and reviews.",
    "Profile photo, if you uploaded one.",
    "Security logs (IP address and sign-in attempts), for 90 days.",
    "We do not store your location. GPS is used only on your phone.",
  ]),
  LegalBlock.h("Delete my account from the app"),
  LegalBlock.p(
    "Go to Profile > Privacy and legal > My data > Delete my account. We'll ask for your password to confirm.",
  ),
  LegalBlock.h("Delete my account if I can't access the app"),
  LegalBlock.p(
    "Email soporte@m3biznovatech.com from your account email with the subject “Eliminar mi cuenta”. We will verify ownership and process your request.",
  ),
  LegalBlock.h("What happens when you request deletion"),
  LegalBlock.ul([
    "Your access is blocked immediately.",
    "You have 14 days to change your mind. Email soporte@m3biznovatech.com.",
    "After that, we delete your profile, favorites, archived destinations, notifications, photo and residence information, and anonymize your name and email.",
    "We keep your reviews without identifying you to improve the model.",
  ]),
  LegalBlock.h("Other rights: access, correction, objection and portability"),
  LegalBlock.p(
    "Email soporte@m3biznovatech.com from your account email and tell us which right you wish to exercise. We will respond within 20 business days. If you are dissatisfied, you can contact Peru's National Personal Data Protection Authority.",
  ),
  LegalBlock.h("Sign out on all my devices"),
  LegalBlock.p(
    "In the app, go to Profile > Privacy and legal > My data > Sign out on all my devices.",
  ),
]);

const LegalDoc _appPermissions = LegalDoc('permisos', "App permissions", [
  LegalBlock.h("What permissions PROXVEL uses and why"),
  LegalBlock.ul([
    "Internet: communicates with our servers for your account, recommendations and destinations, and loads maps.",
    "Approximate location (optional): calculates how far you are from a destination. It is used on your phone and is not sent to or stored on our servers. You can deny it and continue using the app.",
    "Photos (optional): when you choose a profile photo, the app receives only the image you select through your phone's photo picker.",
  ]),
  LegalBlock.h("How to change permissions"),
  LegalBlock.p(
    "Review or revoke permissions in your phone's Settings > Apps > PROXVEL > Permissions.",
  ),
  LegalBlock.h("Notifications"),
  LegalBlock.p(
    "PROXVEL notifications appear in the app under the bell on Home. We do not send push notifications to your phone.",
  ),
]);

const LegalDoc
_sourcesAndLicenses = LegalDoc('fuentes', "Sources and licenses", [
  LegalBlock.h("Data and maps"),
  LegalBlock.ul([
    "Maps: © OpenStreetMap contributors (openstreetmap.org/copyright), under the ODbL license.",
    "Weather: SENAMHI, 1991–2020 climate series.",
    "Visitor arrivals: MINCETUR.",
    "Destination descriptions and guides: prepared by M3Biznovatech from public information. Verify hours and prices with official sources.",
  ]),
  LegalBlock.h("Open-source software"),
  LegalBlock.p(
    "PROXVEL uses open-source components. See their licenses under Open-source licenses.",
  ),
]);

const legalDocsEn = <String, LegalDoc>{
  'privacidad': _privacyPolicy,
  'terminos': _termsOfUse,
  'mis-datos': _myData,
  'permisos': _appPermissions,
  'fuentes': _sourcesAndLicenses,
};
