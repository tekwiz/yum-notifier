# YUM Notifier

https://github.com/maxmedia/yum-notifier

## Prerequisites

* [YUM](http://yum.baseurl.org/) (obviously)
* [AWS CLI](https://aws.amazon.com/cli/)
* An AWS account & credentials for [SES](https://aws.amazon.com/ses/) or an
  [SNS](https://aws.amazon.com/sns/) topic for delivery of notifications

## Install:

```sh
curl -L -o /usr/local/src/yum-notifier-0.2.tar.gz \
  -G https://github.com/maxmedia/yum-notifier/archive/v0.2.tar.gz
tar -C /usr/local/src/ -xzvf /usr/local/src/yum-notifier-0.2.tar.gz
/usr/local/src/yum-notifier-0.2/install.sh
rm -Rf /usr/local/src/yum-notifier-0.2.tar.gz /usr/local/src/yum-notifier-0.2
```

## Configuration:

The configuration file `/etc/yum-notifier.conf` is a basic shell variable definition file.

See [yum-notifier.conf](src/yum-notifier.conf) for inline documentation & examples.

## License

    Copyright 2016 MaxMedia <https://www.maxmedia.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
