# Konfigurácia zoznamu serverov v Hyper-V konzole

Cesta: `C:\Users\<USERNAME>\AppData\Roaming\Microsoft\Windows\Hyper-V\Client\1.0\virtmgmt.VMBrowser.config`

Obsah súboru:
```
<?xml version="1.0" encoding="utf-8"?>
<configuration>
    <Microsoft.Virtualization.Client.VMBrowser.BrowserConfigurationOptions>
        <setting name="SnapshotPaneCollapsed" type="System.Boolean">
            <value>False</value>
        </setting>
        <setting name="MainSplitterRatio" type="System.Single">
            <value>0.5</value>
        </setting>
        <setting name="CurrentVisibleColumns" type="System.String">
            <value>Name:160;State:87;CpuUsage:87;AssignedMemory:120;Uptime:100;Task:200;ConfigurationVersion:87</value>
        </setting>
        <setting name="DontTakeSnapshotBeforeApply" type="System.Int32">
            <value>0</value>
        </setting>
        <setting name="AutoCompleteComputerNames" type="System.String">
            <value>SERVER1;SERVER2;SERVER3</value>
        </setting>
        <setting name="SortColumnIndex" type="System.Int32">
            <value>0</value>
        </setting>
        <setting name="SortDirection" type="System.String">
            <value>Ascending</value>
        </setting>
        <setting name="FirstTimeRunBrowser" type="System.Boolean">
            <value>True</value>
        </setting>
        <setting name="PreviousSelectedServer" type="System.String">
            <value>SERVER1</value>
        </setting>
        <setting name="BrowserComputerNames" type="System.String">
            <value>SERVER1;SERVER2;SERVER3</value>
        </setting>
    </Microsoft.Virtualization.Client.VMBrowser.BrowserConfigurationOptions>
</configuration>
```