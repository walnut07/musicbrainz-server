/*
 * @flow strict
 * Copyright (C) 2023 MetaBrainz Foundation
 *
 * This file is part of MusicBrainz, the open internet music database,
 * and is licensed under the GPL version 2, or (at your option) any
 * later version: http://www.gnu.org/licenses/gpl-2.0.txt
 */

import commaOnlyList
  from '../../static/scripts/common/i18n/commaOnlyList.js';
import HelpIcon from '../../static/scripts/edit/components/HelpIcon.js';
import getRelationshipLinkType
  from '../../static/scripts/edit/utility/getRelationshipLinkType.js';

type Props = {
  +relationships: $ReadOnlyArray<RelationshipT>,
};

const RelationshipDocsTooltip = ({
  relationships,
}: Props): React$Element<'div'> | null => {
  const relationshipTypes = [...new Set(
    relationships.reduce((types: Array<LinkTypeT>, relationship) => {
      const type = getRelationshipLinkType(relationship);
      if (type && type.gid && type.name) {
        types.push(type);
      }
      return types;
    }, []),
  )];

  if (!relationshipTypes?.length) {
    return null;
  }

  const docLinks = relationshipTypes.map(relationshipType => exp.l(
    '“{doc_link|{name}}”',
    {
      doc_link: {
        href: '/relationship/' + relationshipType.gid,
        target: '_blank',
      },
      name: relationshipType.name,
    },
  ));

  const helpContent = (
    exp.l(
      `See the documentation for the relationship types in this edit:
       {doc_links}.`,
      {
        doc_links: commaOnlyList(docLinks),
      },
    )
  );

  return (
    <div className="edit-help">
      <HelpIcon
        content={helpContent}
      />
    </div>
  );
};

export default RelationshipDocsTooltip;
