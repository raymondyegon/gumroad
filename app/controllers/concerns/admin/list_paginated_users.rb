# frozen_string_literal: true

module Admin::ListPaginatedUsers
  extend ActiveSupport::Concern
  include Pagy::Backend

  # We list 5 users per page by default for the following reasons:
  # - Feature: A list of user cards is used for the refund queue or for searching users, so we don't need to display too many users per page to avoid overwhelming the user.
  # - UX: A user card in the admin takes up almost the entire height of the page, so we don't need to display too many users per page since the viewer would not see the entire list.
  # - Performance: Loading a user card is slow because we load a lot of data for each user.
  RECORDS_PER_PAGE = 5

  private
    def list_paginated_users(users:, template:, legacy_template:)
      pagination, users = pagy_countless(
        users,
        limit: params[:per_page] || RECORDS_PER_PAGE,
        page: params[:page],
        countless_minimal: true
      )

      respond_to do |format|
        format.html do
          render(
            inertia: template,
            props: {
              users: InertiaRails.merge do
                users.with_blocked_attributes_for(:form_email, :form_email_domain).map do |user|
                  user.as_json(
                    admin: true,
                    impersonatable: policy([:admin, :impersonators, user]).create?
                  )
                end
              end,
              pagination:
            },
            legacy_template: legacy_template
          )
        end
        format.json { render json: { users:, pagination: } }
      end
    end
end
