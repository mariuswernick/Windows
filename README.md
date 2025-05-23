# Windows File Association Hardening

This repository provides resources for hardening Windows file associations, specifically to help mitigate the risk of malicious file execution by associating potentially dangerous file types with Notepad.

## Purpose

Attackers often use file types such as `.js`, `.vbs`, `.hta`, and others to deliver malware. By changing the default application for these file types to Notepad, you can reduce the risk of accidental execution.

## Contents

- `FileAssociations.xml`: An XML configuration file for use with Windows' `dism` or `dism++` tools to set default file associations for specific file types to Notepad.

## How It Works

The `FileAssociations.xml` file reassigns the default application for a list of potentially dangerous file extensions (e.g., `.js`, `.vbs`, `.wsf`, `.hta`, etc.) to Notepad. This means that double-clicking these files will open them in Notepad, displaying their contents as text rather than executing them.

## Usage

1. **Download or clone this repository.**
2. **Apply the file associations:**
   - Open an elevated (Administrator) Command Prompt or PowerShell.
   - Use a tool like [dism++](https://github.com/Chuyu-Team/Dism-Multi-language) or Windows built-in `dism` to import the XML file.
   - Example with dism++:
     1. Open dism++ as Administrator.
     2. Go to `Toolkit` > `File Association`.
     3. Import `FileAssociations.xml`.
     4. Apply the changes and restart your computer if required.

> **Note:** Changing file associations may affect user experience. Only apply in environments where this is appropriate (e.g., enterprise, lab, or security-hardened systems).

## Contributing

Contributions are welcome! If you have suggestions for additional file types or improvements, please open an issue or submit a pull request.

## License

This repository is licensed under the MIT License.
