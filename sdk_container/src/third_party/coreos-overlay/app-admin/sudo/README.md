## Flatcar changes
- Remove Perl Runtime Dependency
- Remove OpenLDAP schema files for sudo
```
insinto /etc/openldap/schema
newins doc/schema.OpenLDAP sudo.schema
```
- Remove sudo.conf file as it is shipped via baselayout
