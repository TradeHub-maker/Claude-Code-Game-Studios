# Familienbord (iOS, SwiftUI + SwiftData + CloudKit)

Native Version der Web-App. Sechs Bereiche: Plan (Dienst und Termine, Abholung, Überschneidungen),
Listen (Einkauf nach Geschäft, Aufgaben mit Zuständigkeit), Essen (Vorschläge, Abstimmung, Zutaten → Einkaufsliste),
Aufgaben (Punkte, Taschengeld), Dokumente (Fristen, lokale Erinnerung), Chat (Status-Schnellknöpfe).
Siri-Kurzbefehl „Etwas auf die Einkaufsliste in Familienbord setzen“ und ein Einkaufs-Widget sind enthalten.

## Stand

**Nicht gebaut und nicht getestet.** Der Code wurde auf Linux ohne Swift-Compiler geschrieben.
Erwarte beim ersten Build auf dem Mac einzelne Compilerfehler. Die Planungslogik steckt
absichtlich in `Shared/SharedStore.swift` (`Planner`), damit du sie leicht per Unit-Test prüfen kannst.

## Starten (Mac mit Xcode 15+)

1. `brew install xcodegen && xcodegen generate`
2. In `project.yml`, `Shared/SharedStore.swift` und den `.entitlements` `de.example` durch deinen Bundle-Prefix ersetzen, Team-ID eintragen.
3. Im Apple-Developer-Konto: iCloud-Container und App Group anlegen (Namen wie in `project.yml`).
4. `Familienbord.xcodeproj` öffnen, auf einem Gerät starten (CloudKit läuft nicht zuverlässig im Simulator).

## Bekannte Lücken (nächste Schritte)

1. **Teilen zwischen verschiedenen Apple-IDs fehlt.** SwiftData+CloudKit synchronisiert nur die *private* Datenbank
   einer Apple-ID. Für Partner und Kinder mit eigener Apple-ID braucht es CloudKit-Sharing (`CKShare`),
   das SwiftData nicht anbietet. Dafür muss die Speicherschicht auf Core Data (`NSPersistentCloudKitContainer`)
   oder direktes CloudKit umgestellt werden. Das ist der wichtigste nächste Schritt.
2. Taschengeld-Wert pro Punkt gilt nur pro Gerät (`@AppStorage`).
3. Kein Import aus Kalender-Dateien, nur Text-Import des Dienstplans.
4. Erinnerungen für Fristen sind lokal auf dem Gerät, das die Frist anlegt.
5. Kein App-Icon, keine Lokalisierung außer Deutsch, kein Datenschutztext für den App Store.
