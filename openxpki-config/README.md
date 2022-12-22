# OpenXPKI Configuration Repository

**Note**: Some of the items and features mentioned in this document are only accessible using the enterprise configuration which requires a support subscription.

## TL;DR

To start with your own configuration, clone the `community` branch to `/etc/openxpki` and read QUICKSTART.md.

	git clone https://github.com/openxpki/openxpki-config.git --branch=community /etc/openxpki

## How to Start

This repository holds a boilerplate configuration for OpenXPKI which must be installed to  `/etc/openxpki/`.

The upstream repository provides three branches:

| Branch         | Description                                                  |
| -------------- | ------------------------------------------------------------ |
| **master**     | An almost empty branch that holds this README                |
| **community**  | The recommended branch for running an OpenXPKI Community Edition |
| **enterprise** | The recommended branch for running an OpenXPKI Enterprise Edition |

### Single Branch Approach

Create your own branch from master and merge the respective branch as a starting point. We recommend to use the string **customer** as branch name and make a single squashed commit. **Please make sure you record the exact commit you start from as you will not be able to merge upstream changes later.**

```bash
git checkout -b customer
git merge --squash v3.2
git commit -m "Initial Checkout based on v3.2"
```

In case you want to maintain configuration for different environments as branches we recommend to proceed with the customer branch as a starting point and split into different branches later as described below.

### Credentials / Local Users

Credentials and, if used, the local user database are kept in the folder `/etc/openxpk/local`. Those files will will contain passwords in plain text and items like hostnames which will likely depend on the actual environment so we **do not recommend to add them to the repository** but deploy those on the machines manually or by using a provisioning system.

The files are already linked into the configuration layer and must be created before the system can be used. Templates for those files are provided in `contrib/local`, copy the directory  `cp -a /etc/openxpki/contrib/local /etc/openxpki` and adjust the files as needed.

### Define your Realms

Open `config.d/system/realms.yaml` and add your realms.

For each realm, create a corresponding directory in `config.d/realm/`, for a test drive you can just add a symlink to `realm.tpl`, for a production setup we recommend to create a directory and add the basic artefacts as follows:

```bash
mkdir workflow workflow/def profile notification 
ln -s ../../realm.tpl/api/
ln -s ../../realm.tpl/auth/
ln -s ../../realm.tpl/crl/
ln -s ../../realm.tpl/crypto.yaml
ln -s ../../realm.tpl/uicontrol/
cp ../../realm.tpl/profile/default.yaml profile/
ln -s ../../../realm.tpl/profile/template/ profile/
cp ../../realm.tpl/notification/smtp.yaml.sample notification/smtp.yaml
ln -s ../../../realm.tpl/workflow/global workflow/
ln -s ../../../realm.tpl/workflow/persister.yaml workflow/
(cd workflow/def/ && find ../../../../realm.tpl/workflow/def/ -type f | xargs -L1 ln -s)
# In most cases you do not need all workflows and we recommend to remove them
# those items are rarely used
cd workflow/def
rm certificate_export.yaml certificate_revoke_by_entity.yaml report_list.yaml
# if you dont plan to use EST remove those too
rm est_cacerts.yaml est_csrattrs.yaml
```

We recommend to add the "vanilla" files to the repository immediately after copy and before you do **any** changes:

```bash
git -C /etc/openxpki add config.d/
git commit -m "Initial commit with Realms"
```

#### User Home Page

The default configuration has a static HTML page set as the home for the `User` role. The code for this page must be manually placed to `/var/www/static/<realm>/home.html`, an example can be found in the `contrib` directory. If you don't want a static page, remove the `welcome` and `home` items from the `uicontrol/_default.yaml`.

### Define Profiles

To issue certificates you need to define the profiles first. Adjust your realm wide CDP/AIA settings, validity and key parameters in `profile/default.yaml`.

For each profile you want to have in this realm, create a file with the profile name. You can find templates for most use cases in `realm.tpl/profile`, there is also a `sample.yaml` which provides an almost complete reference.

We recommend to have global settings, as most of the extensions, in the `default.yaml` and only put the subject composition and the key usage attributes in the certificate detail file.

### Customize i18n

The folder `contrib/i18n/` contains the translation files from the upstream project. If you need local extensions or want to change individual translations,  create a file named openxpki.local.po and make your changes here - **never touch the openxpki.po file itself**.

You can find a Makefile in the main folder, that can be used to create the required compiled files. Running `make mo` creates the `openxpki.mo` files in the language directories, `make mo-install` deploys them to the system. *Note*: it might be required to restart the webserver to make the changes visible.

## Config Update

There are two strategies to apply enhancements and bug fixes from the upstream repository.

### Direct Merge Strategy

Using `git merge` directly to merge new commits to your customized branch is only recommended if you have not modified your workflows and have only few changes.

You should also review if any relevant changes were made to the files that were copied, e.g. the profiles or the policy files in rpc/est/scep and apply those to your config if required.

### Partial Squash Merge Strategy

The idea behind this approach is to apply all changes from the upstream repository to your local working copy but leave it to the maintainer to bundle them into commits to keep the history small. As the usage of `squash` breaks the history you need to use `cherry-pick` and a temporary branch to prepare the update.

To upgrade the branch `customer` from v3.2 to v3.4 use the following commands:

```bash
git checkout v3.2
git merge --squash v3.4
git commit -m "Upgrade v3.4"
# write down the hash of the commit created
git checkout customer
git cherry-pick <commit>
```

This leaves you with the changes applied to the local filesystem, affected files and conflicts can be viewed using `git status`.

* review and resolve conflicts

* review the changes made in `realm.tpl/workflow/global`, those can usually be applied without any problems as long as you did not make any fundamental changes here.
* review the changes made in `realm.tpl/workflow/def`. If you have modified the default workflows look for any conflicts or possible problems. If you have "forked" away your own workflows by copying them to a realm, check if the changes need to be backported.
* review the other changes and decide if you want to incorporate them. Look for required changes especially in the service configurations (rpc/est/scep).

Git Cheat Sheet:

```bash
# show the history of a files changes on the upstream branch
git log v3.4 -- <filename>

# discard all changes made on a file
git checkout -- <filename>

# replace file with upstream version
git checkout v3.4 -- <filename>

# add only some changes for a file
git reset -- <filename>
git add -p <filename>
git checkout -- <filename>

# review changes made to a single file (after the commit was done)
git show -- <file>

# apply a change from an upstream to a custom file
git show -- <upstream file> | patch <custom file>
```

Make sure you add the exact commit hash from the upstream repository, we recommend to write this into the commit message, e.g.: `git commit -m "Merged upstream changes v3.4"`.

If you have customized i18n files, do not forget to update those after doing the merge.

### Version Tag

The WebUI status page can show information to identify the running config. The Makefile contains a target `make version` which will append the current commit hash to the file `config.d/system/version.yaml`. which will make the commit hash visible on the status page.

### File Permissions

The `config.d` folder and the credential files in `local` should be readable by the `openxpki` user only as they might contain confidential data.

The files for the protocol wrappers (`webui, scep, rpc, est, soap` ) must be readable by the webserver, if you add credentials here make sure to reduce the permissions as far as possible.

## Testing

To setup the templates for automated test scripts based on a KeyWordTesting Framework run `make testlib`. This will add a folder `contrib/test/` with sample files and the library classes.

We recommend to not add the `libs` path to the repository but to pull this on each test as the libraries will encapsulate any version dependent behavior.

## Packaging and Customization

By default, the package name for the configuration packages is 'openxpki-config', this can be customized  via the file `.customerinfo`. The format of this file is KEY=VALUE.

    PKGNAME=openxpki-config-acme
    PKGDESC="OpenXPKI configuration for Acme Corporation"

