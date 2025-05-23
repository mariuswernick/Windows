# Windows File Association Hardening

This repository provides resources for hardening Windows file associations, specifically to help mitigate the risk of malicious file execution by associating potentially dangerous file types with Notepad.

## Purpose

Attackers often use file types such as `.js`, `.vbs`, `.hta`, and others to deliver malware. By changing the default application for these file types to Notepad, you can reduce the risk of accidental execution.

## Contents

- `FileAssociations.xml`: An XML configuration file for use with Windows' management tools to set default file associations for specific file types to Notepad.

## How It Works

The `FileAssociations.xml` file reassigns the default application for a list of potentially dangerous file extensions (e.g., `.js`, `.vbs`, `.wsf`, `.hta`, etc.) to Notepad. This means that double-clicking these files will open them in Notepad, displaying their contents as text rather than executing them.

## Deployment with Intune or Group Policy

You can deploy these file association settings to Windows devices using either Microsoft Intune or Group Policy:

### Microsoft Intune
1. In the Intune admin center, go to **Devices > Configuration profiles**.
2. Create a new profile:
   - **Platform:** Windows 10 and later
   - **Profile type:** Settings catalog
3. In the configuration settings, search for and add **Default Associations Configuration File**.
4. Upload the `FileAssociations.xml` file from this repository.
5. Assign the profile to the desired device groups.
6. Save and deploy the profile. The file associations will be applied to targeted devices after the next sync.

### Group Policy (GPO)
1. Place the `FileAssociations.xml` file on a network share or local path accessible by target computers.
2. Open the Group Policy Management Console (GPMC).
3. Edit or create a GPO linked to your target computers.
4. Navigate to **Computer Configuration > Administrative Templates > Windows Components > File Explorer**.
5. Enable the policy **Set a default associations configuration file** and specify the path to your `FileAssociations.xml` file.
6. Apply the GPO. The associations will be set at next logon or reboot.

> **Note:** Changing file associations may affect user experience. Only apply in environments where this is appropriate (e.g., enterprise, lab, or security-hardened systems).

## Contributing

Contributions are welcome! If you have suggestions for additional file types or improvements, please open an issue or submit a pull request.

## License

This repository is licensed under the MIT License.
