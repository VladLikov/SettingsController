#!/usr/bin/env python3
"""Generate a deterministic, dependency-free Xcode example project."""
import hashlib
import json
import plistlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXAMPLE = ROOT / 'Examples/SettingsExample'
PROJECT = EXAMPLE / 'SettingsExample.xcodeproj'
objects = {}

def uid(label):
    return hashlib.sha1(label.encode()).hexdigest()[:24].upper()

def obj(label, isa, **values):
    key = uid(label)
    objects[key] = dict(isa=isa, **values)
    return key

def encode(value, indent=0):
    tab = '\t' * indent
    if isinstance(value, dict):
        return '{\n' + ''.join('\t' * (indent + 1) + json.dumps(str(k)) + ' = ' + encode(v, indent + 1) + ';\n' for k, v in value.items()) + tab + '}'
    if isinstance(value, list):
        return '(\n' + ''.join('\t' * (indent + 1) + encode(v, indent + 1) + ',\n' for v in value) + tab + ')'
    return json.dumps(str(value))

app_source = obj('app-source', 'PBXFileReference', lastKnownFileType='sourcecode.swift', path='App.swift', sourceTree='<group>')
test_source = obj('test-source', 'PBXFileReference', lastKnownFileType='sourcecode.swift', path='UITests.swift', sourceTree='<group>')
info = obj('info', 'PBXFileReference', lastKnownFileType='text.plist.xml', path='Info.plist', sourceTree='<group>')
app_product = obj('app-product', 'PBXFileReference', explicitFileType='wrapper.application', path='SettingsExample.app', sourceTree='BUILT_PRODUCTS_DIR')
test_product = obj('test-product', 'PBXFileReference', explicitFileType='wrapper.cfbundle', path='SettingsExampleUITests.xctest', sourceTree='BUILT_PRODUCTS_DIR')
products = obj('products', 'PBXGroup', children=[app_product, test_product], name='Products', sourceTree='<group>')
main_group = obj('main-group', 'PBXGroup', children=[app_source, test_source, info, products], sourceTree='<group>')
package = obj('local-package', 'XCLocalSwiftPackageReference', relativePath='../..')
product = obj('package-product', 'XCSwiftPackageProductDependency', productName='SettingsController', package=package)
app_build = obj('app-build', 'PBXBuildFile', fileRef=app_source)
test_build = obj('test-build', 'PBXBuildFile', fileRef=test_source)
package_build = obj('package-build', 'PBXBuildFile', productRef=product)

def phase(label, isa, files):
    return obj(label, isa, buildActionMask='2147483647', files=files, runOnlyForDeploymentPostprocessing='0')

app_phases = [phase('app-sources', 'PBXSourcesBuildPhase', [app_build]), phase('app-frameworks', 'PBXFrameworksBuildPhase', [package_build]), phase('app-resources', 'PBXResourcesBuildPhase', [])]
test_phases = [phase('test-sources', 'PBXSourcesBuildPhase', [test_build]), phase('test-frameworks', 'PBXFrameworksBuildPhase', []), phase('test-resources', 'PBXResourcesBuildPhase', [])]
base = dict(SWIFT_VERSION='6.0', IPHONEOS_DEPLOYMENT_TARGET='15.0', SDKROOT='iphoneos', CLANG_ENABLE_MODULES='YES', TARGETED_DEVICE_FAMILY='1,2', CODE_SIGN_STYLE='Automatic', ENABLE_USER_SCRIPT_SANDBOXING='YES')

def configurations(label, settings):
    ids = []
    for name in ['Debug', 'Release']:
        values = dict(settings)
        values.update(SWIFT_OPTIMIZATION_LEVEL='-Onone' if name == 'Debug' else '-O', DEBUG_INFORMATION_FORMAT='dwarf' if name == 'Debug' else 'dwarf-with-dsym', ONLY_ACTIVE_ARCH='YES' if name == 'Debug' else 'NO')
        if name == 'Debug':
            values.update(ENABLE_TESTABILITY='YES', SWIFT_ACTIVE_COMPILATION_CONDITIONS='DEBUG')
        ids.append(obj(label + name, 'XCBuildConfiguration', buildSettings=values, name=name))
    return obj(label + 'list', 'XCConfigurationList', buildConfigurations=ids, defaultConfigurationIsVisible='0', defaultConfigurationName='Release')

project_configs = configurations('project-config', base)
app_configs = configurations('app-config', dict(PRODUCT_NAME='$(TARGET_NAME)', PRODUCT_BUNDLE_IDENTIFIER='com.example.SettingsControllerExample', INFOPLIST_FILE='Info.plist', GENERATE_INFOPLIST_FILE='NO', LD_RUNPATH_SEARCH_PATHS=['$(inherited)', '@executable_path/Frameworks'], ASSETCATALOG_COMPILER_APPICON_NAME='', CURRENT_PROJECT_VERSION='1', MARKETING_VERSION='1.0'))
test_configs = configurations('test-config', dict(PRODUCT_NAME='$(TARGET_NAME)', PRODUCT_BUNDLE_IDENTIFIER='com.example.SettingsControllerExample.UITests', GENERATE_INFOPLIST_FILE='YES', TEST_TARGET_NAME='SettingsExample', LD_RUNPATH_SEARCH_PATHS=['$(inherited)', '@executable_path/Frameworks', '@loader_path/Frameworks']))
app_target = obj('app-target', 'PBXNativeTarget', buildConfigurationList=app_configs, buildPhases=app_phases, buildRules=[], dependencies=[], name='SettingsExample', packageProductDependencies=[product], productName='SettingsExample', productReference=app_product, productType='com.apple.product-type.application')
proxy = obj('proxy', 'PBXContainerItemProxy', containerPortal=uid('project'), proxyType='1', remoteGlobalIDString=app_target, remoteInfo='SettingsExample')
dependency = obj('test-dependency', 'PBXTargetDependency', target=app_target, targetProxy=proxy)
test_target = obj('test-target', 'PBXNativeTarget', buildConfigurationList=test_configs, buildPhases=test_phases, buildRules=[], dependencies=[dependency], name='SettingsExampleUITests', productName='SettingsExampleUITests', productReference=test_product, productType='com.apple.product-type.bundle.ui-testing')
project = obj('project', 'PBXProject', attributes=dict(BuildIndependentTargetsInParallel='YES', LastUpgradeCheck='2600', TargetAttributes={app_target: dict(CreatedOnToolsVersion='26.0'), test_target: dict(CreatedOnToolsVersion='26.0', TestTargetID=app_target)}), buildConfigurationList=project_configs, compatibilityVersion='Xcode 14.0', developmentRegion='en', hasScannedForEncodings='0', knownRegions=['en', 'ru', 'Base'], mainGroup=main_group, packageReferences=[package], productRefGroup=products, projectDirPath='', projectRoot='', targets=[app_target, test_target])
PROJECT.mkdir(parents=True, exist_ok=True)
(PROJECT / 'project.pbxproj').write_text('// !$*UTF8*$!\n' + encode(dict(archiveVersion='1', classes={}, objectVersion='56', objects=objects, rootObject=project)) + '\n')
info_values = dict(CFBundleDevelopmentRegion='en', CFBundleExecutable='$(EXECUTABLE_NAME)', CFBundleIdentifier='$(PRODUCT_BUNDLE_IDENTIFIER)', CFBundleInfoDictionaryVersion='6.0', CFBundleName='$(PRODUCT_NAME)', CFBundlePackageType='APPL', CFBundleShortVersionString='1.0', CFBundleVersion='1', LSRequiresIPhoneOS=True, UILaunchScreen={}, UIApplicationSceneManifest={'UIApplicationSupportsMultipleScenes': False, 'UISceneConfigurations': {}}, UISupportedInterfaceOrientations=['UIInterfaceOrientationPortrait', 'UIInterfaceOrientationLandscapeLeft', 'UIInterfaceOrientationLandscapeRight'], UIRequiredDeviceCapabilities=['arm64'])
with (EXAMPLE / 'Info.plist').open('wb') as handle:
    plistlib.dump(info_values, handle)
reference = lambda identifier, name: f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{identifier}" BuildableName="{name}" BlueprintName="{name.split(".")[0]}" ReferencedContainer="container:SettingsExample.xcodeproj"/>'
scheme = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2600" version="1.7">
  <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries>
    <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{reference(app_target, 'SettingsExample.app')}</BuildActionEntry>
  </BuildActionEntries></BuildAction>
  <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables>
    <TestableReference skipped="NO" parallelizable="NO">{reference(test_target, 'SettingsExampleUITests.xctest')}</TestableReference>
  </Testables></TestAction>
  <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{reference(app_target, 'SettingsExample.app')}</BuildableProductRunnable></LaunchAction>
  <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{reference(app_target, 'SettingsExample.app')}</BuildableProductRunnable></ProfileAction>
  <AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
'''
schemes = PROJECT / 'xcshareddata/xcschemes'
schemes.mkdir(parents=True, exist_ok=True)
(schemes / 'SettingsExample.xcscheme').write_text(scheme)
print(PROJECT)
