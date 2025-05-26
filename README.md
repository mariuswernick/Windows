# Windows Tools & PowerShell Scripts

A collection of useful Windows administration tools, PowerShell scripts, and utilities for system management and automation.

## 🛠️ Contents

This repository contains various tools and scripts for Windows environments:

### File Management & Security
- **FileAssociations.xml** - Configuration for hardening Windows file associations by redirecting potentially dangerous file types to Notepad

### PowerShell Scripts
*Coming soon - PowerShell scripts for various administrative tasks*

### System Utilities  
*Coming soon - Additional Windows tools and utilities*

## 📋 Requirements

- Windows 10/11 or Windows Server 2016+
- PowerShell 5.1 or later (PowerShell 7+ recommended for newer scripts)
- Administrative privileges may be required for some tools

## 🚀 Usage

### File Association Hardening

The `FileAssociations.xml` file can be deployed via:

**Microsoft Intune:**
1. Navigate to **Devices > Configuration profiles**
2. Create new profile (Windows 10+, Settings catalog)
3. Add **Default Associations Configuration File**
4. Upload the XML file and assign to device groups

**Group Policy:**
1. Place XML file on accessible network share
2. Edit GPO: **Computer Configuration > Administrative Templates > Windows Components > File Explorer**
3. Enable **Set a default associations configuration file**
4. Specify path to XML file

### PowerShell Scripts

Each PowerShell script includes:
- Purpose and functionality description
- Required permissions
- Usage examples
- Parameter documentation

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add your tool/script with proper documentation
4. Submit a pull request

For PowerShell scripts, please include:
- Comment-based help
- Error handling
- Input validation
- Usage examples

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

## ⚠️ Disclaimer

These tools are provided as-is for educational and administrative purposes. Test thoroughly in non-production environments before deployment. Some tools may affect system behavior or user experience.

## 📞 Support

If you encounter issues or have suggestions:
- Open an issue on GitHub
- Provide detailed error messages and environment information
- Include steps to reproduce any problems